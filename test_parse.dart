void main() {
  final json = {
    "instructorId": {
      "firstName": "John",
      "lastName": "Doe"
    }
  };

  final res = json['instructor']?['email']?.toString() 
      ?? json['allocatedInstructorEmail']?.toString() 
      ?? (json['instructorId'] is Map 
          ? '${(json['instructorId'] as Map)['firstName']} ${(json['instructorId'] as Map)['lastName']}' 
          : '');

  print('Result: "$res"');
}
