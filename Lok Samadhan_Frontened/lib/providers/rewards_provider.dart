import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reward_item.dart';
import '../models/reward_transaction.dart';
import '../models/reward_claim.dart';
import '../models/rewards_summary.dart';
import '../services/api_service.dart';

class RedemptionResult {
  final bool success;
  final bool isInsufficient;
  final String? message;
  final String? rewardName;
  final int? cost;
  final int? previousBalance;
  final int? remainingBalance;
  final int? coinsNeeded;
  final int? additionalComplaintsNeeded;

  const RedemptionResult({
    required this.success,
    this.isInsufficient = false,
    this.message,
    this.rewardName,
    this.cost,
    this.previousBalance,
    this.remainingBalance,
    this.coinsNeeded,
    this.additionalComplaintsNeeded,
  });
}

class AwardResult {
  final bool success;
  final bool alreadyAwarded;
  final int coinsEarned;
  final String complaintId;
  final int balanceBefore;
  final int balanceAfter;
  final String message;

  const AwardResult({
    required this.success,
    required this.alreadyAwarded,
    required this.coinsEarned,
    required this.complaintId,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.message,
  });
}

class RewardsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  RewardsSummary _summary = RewardsSummary.initial();
  List<RewardItem> _catalogue = [];
  List<RewardTransaction> _transactions = [];
  List<RewardClaim> _claimedRewards = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _activeUserId = 'default_citizen';

  // Getters
  RewardsSummary get summary => _summary;
  int get balance => _summary.balance;
  int get eligibleComplaintsCount => _summary.eligibleComplaintsCount;
  int get rewardsRedeemedCount => _summary.rewardsRedeemedCount;
  List<RewardItem> get catalogue => _catalogue;
  List<RewardTransaction> get transactions => _transactions;
  List<RewardClaim> get claimedRewards => _claimedRewards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get activeUserId => _activeUserId;

  RewardsProvider() {
    _initLocalCacheAndLoad();
  }

  static const String _prefBalanceKey = 'lok_samadhan_gc_summary_v2';
  static const String _prefTransactionsKey = 'lok_samadhan_gc_transactions_v2';
  static const String _prefClaimsKey = 'lok_samadhan_gc_claims_v2';

  void setActiveUser(String? userId) {
    final clean = (userId != null && userId.trim().isNotEmpty) ? userId.trim() : 'default_citizen';
    if (_activeUserId != clean) {
      _activeUserId = clean;
      loadRewards();
    }
  }

  /// 1. Initialize local cache and sync with server
  Future<void> _initLocalCacheAndLoad() async {
    await _loadFromLocalCache();
    await loadRewards();
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear legacy 10 GC caches from earlier versions
      if (prefs.containsKey('lok_samadhan_gc_summary')) {
        await prefs.remove('lok_samadhan_gc_summary');
      }
      if (prefs.containsKey('lok_samadhan_gc_transactions')) {
        await prefs.remove('lok_samadhan_gc_transactions');
      }

      final summaryStr = prefs.getString(_prefBalanceKey);
      if (summaryStr != null) {
        _summary = RewardsSummary.fromJson(jsonDecode(summaryStr));
      }

      final txStr = prefs.getString(_prefTransactionsKey);
      if (txStr != null) {
        final list = jsonDecode(txStr) as List;
        _transactions = list
            .map((i) => RewardTransaction.fromJson(i))
            .where((tx) => tx.referenceId != 'WELCOME-BONUS' && tx.id != 'TXN-INIT-001')
            .toList();
      } else {
        _transactions = [];
      }

      final claimStr = prefs.getString(_prefClaimsKey);
      if (claimStr != null) {
        final list = jsonDecode(claimStr) as List;
        _claimedRewards = list.map((i) => RewardClaim.fromJson(i)).toList();
      }

      if (_catalogue.isEmpty) {
        _catalogue = ApiService.defaultFallbackCatalogue;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[RewardsProvider] Cache load warning: $e');
    }
  }

  Future<void> _saveToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefBalanceKey, jsonEncode(_summary.toJson()));
      await prefs.setString(
        _prefTransactionsKey,
        jsonEncode(_transactions.map((t) => t.toJson()).toList()),
      );
      await prefs.setString(
        _prefClaimsKey,
        jsonEncode(_claimedRewards.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[RewardsProvider] Cache save error: $e');
    }
  }

  /// 2. Load all rewards data from backend (Database is single source of truth)
  Future<void> loadRewards() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      // Fetch catalogue
      final items = await _apiService.fetchRewardCatalogue();
      if (items.isNotEmpty) {
        _catalogue = items;
      } else if (_catalogue.isEmpty) {
        _catalogue = ApiService.defaultFallbackCatalogue;
      }

      // Fetch authoritative summary from backend
      final remoteSummary = await _apiService.fetchRewardsSummary(_activeUserId);
      if (remoteSummary != null) {
        _summary = remoteSummary;
      }

      // Fetch transactions
      final remoteTx = await _apiService.fetchRewardTransactions(_activeUserId);
      if (remoteTx != null) {
        _transactions = remoteTx
            .where((tx) => tx.referenceId != 'WELCOME-BONUS' && tx.id != 'TXN-INIT-001')
            .toList();
      }

      // Fetch claims
      final remoteClaims = await _apiService.fetchClaimedRewards(_activeUserId);
      if (remoteClaims != null) {
        _claimedRewards = remoteClaims;
      }

      await _saveToLocalCache();
    } catch (e) {
      debugPrint('[RewardsProvider] Load error, using cached: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshRewards() => loadRewards();

  /// 3. Apply confirmed reward info directly from complaint creation backend response
  Future<AwardResult> applyBackendRewardInfo(Map<String, dynamic> rewardInfo, String complaintId) async {
    final cleanId = complaintId.trim().toUpperCase();
    final isSuccess = rewardInfo['success'] == true;
    final isAlreadyAwarded = rewardInfo['alreadyAwarded'] == true;

    final balanceBefore = (rewardInfo['balanceBefore'] is int)
        ? rewardInfo['balanceBefore'] as int
        : _summary.balance;
    final balanceAfter = (rewardInfo['balanceAfter'] is int)
        ? rewardInfo['balanceAfter'] as int
        : (balanceBefore + 1);

    if (isSuccess || (isAlreadyAwarded && (balanceAfter > _summary.balance || _summary.balance == 0))) {
      final newBal = balanceAfter > _summary.balance ? balanceAfter : (_summary.balance + 1);
      final prevBal = balanceBefore;

      _summary = _summary.copyWith(
        balance: newBal,
        totalEarned: _summary.totalEarned < newBal ? newBal : (_summary.totalEarned + 1),
        eligibleComplaintsCount: _summary.eligibleComplaintsCount + 1,
      );

      final newTx = RewardTransaction(
        id: 'TXN-EARN-${DateTime.now().millisecondsSinceEpoch}',
        userId: _activeUserId,
        type: 'earned',
        amount: 1,
        description: 'Eligible Complaint #$cleanId',
        referenceId: cleanId,
        balanceAfter: newBal,
        createdAt: DateTime.now(),
      );

      _transactions.removeWhere((tx) => tx.referenceId?.toUpperCase() == cleanId);
      _transactions.insert(0, newTx);

      await _saveToLocalCache();
      notifyListeners();

      // Asynchronously refresh full ledger from server to ensure perfect consistency
      loadRewards();

      return AwardResult(
        success: true,
        alreadyAwarded: false,
        coinsEarned: 1,
        complaintId: cleanId,
        balanceBefore: prevBal,
        balanceAfter: newBal,
        message: rewardInfo['message'] ??
            '🎉 Complaint Submitted Successfully!\nYou earned +1 Grievance Coin (GC).\nYour new balance: $newBal GC',
      );
    }

    if (isAlreadyAwarded) {
      await loadRewards();
      return AwardResult(
        success: false,
        alreadyAwarded: true,
        coinsEarned: 0,
        complaintId: cleanId,
        balanceBefore: _summary.balance,
        balanceAfter: _summary.balance,
        message: rewardInfo['message'] ?? 'Complaint #$cleanId has already earned Grievance Coins.',
      );
    }

    return AwardResult(
      success: false,
      alreadyAwarded: false,
      coinsEarned: 0,
      complaintId: cleanId,
      balanceBefore: _summary.balance,
      balanceAfter: _summary.balance,
      message: rewardInfo['message'] ?? 'Could not award Grievance Coin at this time.',
    );
  }

  /// 4. Award 1 GC for an eligible complaint by contacting backend or local fallback
  Future<AwardResult> awardEligibleComplaint(String complaintId, {String? description}) async {
    final cleanId = complaintId.trim().toUpperCase();

    // 1. Strict deduplication check: Has this exact complaint already earned coins in our active session ledger?
    final isAlreadyAwardedLocally = _transactions.any(
      (tx) => tx.referenceId?.toUpperCase() == cleanId && tx.type == 'earned',
    );
    if (isAlreadyAwardedLocally) {
      return AwardResult(
        success: false,
        alreadyAwarded: true,
        coinsEarned: 0,
        complaintId: cleanId,
        balanceBefore: _summary.balance,
        balanceAfter: _summary.balance,
        message: 'Complaint #$cleanId has already earned Grievance Coins.',
      );
    }

    final prevBal = _summary.balance;
    int newBal = prevBal + 1;
    String awardMsg = '🎉 Complaint Submitted Successfully!\nYou earned +1 Grievance Coin (GC).\nYour new balance: $newBal GC';

    try {
      final res = await _apiService.awardComplaintReward(
        userId: _activeUserId,
        complaintId: cleanId,
        description: description,
      );

      final data = (res['data'] != null && res['data'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(res['data'])
          : null;

      if (res['success'] == true && data != null) {
        // Backend successfully registered or confirmed the award
        final serverBalAfter = data['balanceAfter'] as int?;
        if (serverBalAfter != null && serverBalAfter > prevBal) {
          newBal = serverBalAfter;
        }
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          awardMsg = data['message'].toString();
        }
      } else if (res['alreadyAwarded'] == true) {
        // Backend createGrievance call already created & awarded this complaint!
        // Treat as SUCCESS for this newly submitted complaint in this session flow!
        final serverBalAfter = data?['balanceAfter'] as int?;
        if (serverBalAfter != null && serverBalAfter > prevBal) {
          newBal = serverBalAfter;
        }
      }
    } catch (e) {
      debugPrint('[RewardsProvider] Server award sync note (proceeding offline): $e');
    }

    // 2. Apply the award locally to guarantee state update and persistent cache
    _summary = _summary.copyWith(
      balance: newBal,
      totalEarned: _summary.totalEarned < newBal ? newBal : (_summary.totalEarned + 1),
      eligibleComplaintsCount: _summary.eligibleComplaintsCount + 1,
    );

    final newTx = RewardTransaction(
      id: 'TXN-EARN-${DateTime.now().millisecondsSinceEpoch}',
      userId: _activeUserId,
      type: 'earned',
      amount: 1,
      description: description ?? 'Eligible Complaint #$cleanId',
      referenceId: cleanId,
      balanceAfter: newBal,
      createdAt: DateTime.now(),
    );

    _transactions.removeWhere((tx) => tx.referenceId?.toUpperCase() == cleanId);
    _transactions.insert(0, newTx);

    await _saveToLocalCache();
    notifyListeners();

    return AwardResult(
      success: true,
      alreadyAwarded: false,
      coinsEarned: 1,
      complaintId: cleanId,
      balanceBefore: prevBal,
      balanceAfter: newBal,
      message: awardMsg,
    );
  }

  /// 5. Redeem Demo Reward with Strict Insufficient Coins Validation
  Future<RedemptionResult> redeemReward(RewardItem reward) async {
    final currentBal = _summary.balance;

    // Frontend pre-check
    if (currentBal < reward.cost) {
      final coinsNeeded = reward.cost - currentBal;
      final msg = 'Not enough Grievance Coins!\n'
          'You need ${reward.cost} GC to redeem this reward, but you currently have $currentBal GC.\n\n'
          'Earn $coinsNeeded more GC by submitting eligible complaints '
          '(equivalent to $coinsNeeded additional eligible complaints).';

      return RedemptionResult(
        success: false,
        isInsufficient: true,
        message: msg,
        rewardName: reward.name,
        cost: reward.cost,
        previousBalance: currentBal,
        remainingBalance: currentBal,
        coinsNeeded: coinsNeeded,
        additionalComplaintsNeeded: coinsNeeded,
      );
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Backend validates balance atomically and executes deduction
      final apiRes = await _apiService.redeemReward(
        userId: _activeUserId,
        rewardId: reward.id,
      );

      if (apiRes['success'] == true) {
        final balBefore = (apiRes['data']?['previousBalance'] is int)
            ? apiRes['data']['previousBalance'] as int
            : currentBal;
        final balAfter = (apiRes['data']?['remainingBalance'] is int)
            ? apiRes['data']['remainingBalance'] as int
            : (balBefore - reward.cost);
        final redemptionId = apiRes['data']?['redemptionId']?.toString() ??
            'RDM-${DateTime.now().millisecondsSinceEpoch}';

        // Update local state directly with authoritative backend response
        _summary = _summary.copyWith(
          balance: balAfter,
          totalRedeemed: _summary.totalRedeemed + reward.cost,
          rewardsRedeemedCount: _summary.rewardsRedeemedCount + 1,
        );

        final claim = RewardClaim(
          id: redemptionId,
          userId: _activeUserId,
          rewardId: reward.id,
          rewardName: reward.name,
          coinsDeducted: reward.cost,
          status: 'Demo Claimed',
          createdAt: DateTime.now(),
        );
        _claimedRewards.insert(0, claim);

        final tx = RewardTransaction(
          id: 'TXN-RDM-${DateTime.now().millisecondsSinceEpoch}',
          userId: _activeUserId,
          type: 'redeemed',
          amount: -reward.cost,
          description: 'Redeemed ${reward.name}',
          referenceId: redemptionId,
          balanceAfter: balAfter,
          createdAt: DateTime.now(),
        );
        _transactions.insert(0, tx);

        await _saveToLocalCache();
        notifyListeners();

        // Refresh ledger from server
        loadRewards();

        return RedemptionResult(
          success: true,
          isInsufficient: false,
          rewardName: reward.name,
          cost: reward.cost,
          previousBalance: balBefore,
          remainingBalance: balAfter,
          message: '🎉 Reward Claimed Successfully!\n'
              'You claimed: ${reward.name}\n'
              '${reward.cost} GC deducted.\n'
              'Remaining balance: $balAfter GC',
        );
      } else if (apiRes['error'] == 'INSUFFICIENT_COINS') {
        final coinsNeeded = apiRes['details']?['coinsNeeded'] ?? (reward.cost - currentBal);
        return RedemptionResult(
          success: false,
          isInsufficient: true,
          message: apiRes['message'] ?? 'Not enough Grievance Coins to redeem this reward.',
          rewardName: reward.name,
          cost: reward.cost,
          coinsNeeded: coinsNeeded is int ? coinsNeeded : null,
          additionalComplaintsNeeded: coinsNeeded is int ? coinsNeeded : null,
        );
      } else {
        // Offline / localhost fallback demo redemption
        final balBefore = currentBal;
        final balAfter = balBefore - reward.cost;
        final redemptionId = 'RDM-DEMO-${DateTime.now().millisecondsSinceEpoch}';

        _summary = _summary.copyWith(
          balance: balAfter,
          totalRedeemed: _summary.totalRedeemed + reward.cost,
          rewardsRedeemedCount: _summary.rewardsRedeemedCount + 1,
        );

        final claim = RewardClaim(
          id: redemptionId,
          userId: _activeUserId,
          rewardId: reward.id,
          rewardName: reward.name,
          coinsDeducted: reward.cost,
          status: 'Demo Claimed (Local)',
          createdAt: DateTime.now(),
        );
        _claimedRewards.insert(0, claim);

        final tx = RewardTransaction(
          id: 'TXN-RDM-${DateTime.now().millisecondsSinceEpoch}',
          userId: _activeUserId,
          type: 'redeemed',
          amount: -reward.cost,
          description: 'Redeemed ${reward.name}',
          referenceId: redemptionId,
          balanceAfter: balAfter,
          createdAt: DateTime.now(),
        );
        _transactions.insert(0, tx);

        await _saveToLocalCache();
        notifyListeners();

        return RedemptionResult(
          success: true,
          isInsufficient: false,
          rewardName: reward.name,
          cost: reward.cost,
          previousBalance: balBefore,
          remainingBalance: balAfter,
          message: '🎉 Reward Claimed Successfully!\n'
              'You claimed: ${reward.name}\n'
              '${reward.cost} GC deducted.\n'
              'Remaining balance: $balAfter GC',
        );
      }
    } catch (e) {
      debugPrint('[RewardsProvider] Redemption error, using local fallback: $e');
      if (currentBal >= reward.cost) {
        final balBefore = currentBal;
        final balAfter = balBefore - reward.cost;
        final redemptionId = 'RDM-DEMO-${DateTime.now().millisecondsSinceEpoch}';

        _summary = _summary.copyWith(
          balance: balAfter,
          totalRedeemed: _summary.totalRedeemed + reward.cost,
          rewardsRedeemedCount: _summary.rewardsRedeemedCount + 1,
        );

        final claim = RewardClaim(
          id: redemptionId,
          userId: _activeUserId,
          rewardId: reward.id,
          rewardName: reward.name,
          coinsDeducted: reward.cost,
          status: 'Demo Claimed (Local)',
          createdAt: DateTime.now(),
        );
        _claimedRewards.insert(0, claim);

        final tx = RewardTransaction(
          id: 'TXN-RDM-${DateTime.now().millisecondsSinceEpoch}',
          userId: _activeUserId,
          type: 'redeemed',
          amount: -reward.cost,
          description: 'Redeemed ${reward.name}',
          referenceId: redemptionId,
          balanceAfter: balAfter,
          createdAt: DateTime.now(),
        );
        _transactions.insert(0, tx);

        await _saveToLocalCache();
        notifyListeners();

        return RedemptionResult(
          success: true,
          isInsufficient: false,
          rewardName: reward.name,
          cost: reward.cost,
          previousBalance: balBefore,
          remainingBalance: balAfter,
          message: '🎉 Reward Claimed Successfully!\n'
              'You claimed: ${reward.name}\n'
              '${reward.cost} GC deducted.\n'
              'Remaining balance: $balAfter GC',
        );
      }
      return RedemptionResult(
        success: false,
        message: 'Failed to process redemption: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
