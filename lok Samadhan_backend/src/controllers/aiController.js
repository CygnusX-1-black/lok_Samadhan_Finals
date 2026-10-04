const aiService = require('../services/aiService');
const grievanceService = require('../services/grievanceService');
const { successResponse, errorResponse } = require('../utils/response');

class AIController {
  /**
   * POST /api/ai/classify
   * Body: { text: "...", locationHint: { ... } }
   */
  async classify(req, res) {
    try {
      const { text, locationHint } = req.body;
      if (!text) {
        return errorResponse(res, 'text is required for classification', 400);
      }

      const result = await aiService.classifyGrievance(text, locationHint || {});
      return successResponse(res, result, 'Complaint classified successfully via Gemma/Gemini');
    } catch (err) {
      return errorResponse(res, err.message, 500);
    }
  }

  /**
   * POST /api/ai/chat
   * Body: { message: "...", history: [...], activeDraft: {...} }
   */
  async chat(req, res) {
    try {
      const { message, history, activeDraft } = req.body;
      if (!message) {
        return errorResponse(res, 'message is required', 400);
      }

      const response = await aiService.chatWithAssistant(message, history || [], activeDraft);
      return successResponse(res, response, 'AI response generated');
    } catch (err) {
      return errorResponse(res, err.message, 500);
    }
  }

  /**
   * POST /api/ai/analyze-image
   * Body or multipart: base64 image or file upload with description
   */
  async analyzeImage(req, res) {
    try {
      let imageBuffer;
      let mimeType = 'image/jpeg';
      const description = req.body.description || '';

      if (req.file) {
        imageBuffer = req.file.buffer;
        mimeType = req.file.mimetype;
      } else if (req.body.imageBase64) {
        imageBuffer = Buffer.from(req.body.imageBase64, 'base64');
        mimeType = req.body.mimeType || 'image/jpeg';
      } else {
        return errorResponse(res, 'Either image file or imageBase64 is required', 400);
      }

      const analysis = await aiService.analyzeCivicImage(imageBuffer, mimeType, description);
      return successResponse(res, analysis, 'Image analyzed successfully');
    } catch (err) {
      return errorResponse(res, err.message, 500);
    }
  }

  /**
   * POST /api/ai/suggest-resolution
   * Body: { grievanceId: "..." } or grievance object
   */
  async suggestResolution(req, res) {
    try {
      const { grievanceId, grievanceData } = req.body;
      let target = grievanceData;

      if (!target && grievanceId) {
        target = await grievanceService.getGrievanceById(grievanceId);
      }

      if (!target) {
        return errorResponse(res, 'Grievance not found or grievanceData not provided', 404);
      }

      const suggestion = await aiService.suggestOfficialResolution(target);
      return successResponse(res, suggestion, 'Official redressal suggestion drafted');
    } catch (err) {
      return errorResponse(res, err.message, 500);
    }
  }
}

module.exports = new AIController();
