class EmergencyResponse {
  final bool success;
  final int? callId;
  final String message;
  final List<String>? smsErrors;

  EmergencyResponse({
    required this.success,
    this.callId,
    required this.message,
    this.smsErrors,
  });

  factory EmergencyResponse.fromJson(Map<String, dynamic> json) {
    return EmergencyResponse(
      success: json['success'] ?? false,
      callId: json['call_id'],
      message: json['message'] ?? 'Resposta do servidor',
      smsErrors: json['sms_errors'] != null
          ? List<String>.from(json['sms_errors'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'call_id': callId,
      'message': message,
      if (smsErrors != null) 'sms_errors': smsErrors,
    };
  }

  @override
  String toString() {
    return 'EmergencyResponse(success: $success, callId: $callId, message: $message, smsErrors: $smsErrors)';
  }
}
