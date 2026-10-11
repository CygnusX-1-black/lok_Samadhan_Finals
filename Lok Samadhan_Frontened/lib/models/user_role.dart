enum UserPersona {
  citizen,
  governmentOfficial,
}

extension UserPersonaExtension on UserPersona {
  String get title {
    switch (this) {
      case UserPersona.citizen:
        return 'Nagarik Portal (Citizen Mode)';
      case UserPersona.governmentOfficial:
        return 'Govt Officer Dashboard (Admin)';
    }
  }

  String get shortName {
    switch (this) {
      case UserPersona.citizen:
        return 'Citizen / nagarik';
      case UserPersona.governmentOfficial:
        return 'Officer / adhikari';
    }
  }

  String get description {
    switch (this) {
      case UserPersona.citizen:
        return 'Lodge complaints by speaking in regional dialects & track resolution.';
      case UserPersona.governmentOfficial:
        return 'Triage incoming voice complaints, manage SLAs & HITL fallback queue.';
    }
  }
}
