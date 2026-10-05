/// Local dummy data for the Admin Panel. Replace with a backend later.
class AdminData {
  // Available blood groups
  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Donor data
  static final List<Map<String, dynamic>> donors = [
    {
      'id': 1,
      'name': 'Pratik Nakum',
      'location': 'Raiya Road, Rajkot',
      'bloodType': 'AB+',
    },
    {
      'id': 2,
      'name': 'Pratik Nakum',
      'location': 'Rajya Road, Rajkot',
      'bloodType': 'O+',
    },
    {
      'id': 3,
      'name': 'Pratik Nakum',
      'location': 'Raiya Road, Rajkot',
      'bloodType': 'AB+',
    },
    {
      'id': 4,
      'name': 'Karan Patel',
      'location': 'Kalawad Road, Rajkot',
      'bloodType': 'O+',
    },
    {
      'id': 5,
      'name': 'Neha Shah',
      'location': 'University Road, Rajkot',
      'bloodType': 'B+',
    },
    {
      'id': 6,
      'name': 'Amit Joshi',
      'location': 'Yagnik Road, Rajkot',
      'bloodType': 'A+',
    },
    {
      'id': 7,
      'name': 'Riya Mehta',
      'location': 'Mavdi, Rajkot',
      'bloodType': 'AB+',
    },
    {
      'id': 8,
      'name': 'Harsh Desai',
      'location': 'Gondal Road, Rajkot',
      'bloodType': 'O+',
    },
  ];

  // Blood request data
  static final List<Map<String, dynamic>> requests = [
    {
      'id': 1,
      'status': 'Normal',
      'hospital': 'Civil Hospital',
      'location': 'Hospital chowk, Rajkot',
      'patient': 'Pratik Nakum',
      'bloodType': 'AB+',
      'units': '3 Units',
      'decision': 'pending',
    },
    {
      'id': 2,
      'status': 'Critical',
      'hospital': 'Civil Hospital',
      'location': 'Hospital chowk, Rajkot',
      'patient': 'Pratik Nakum',
      'bloodType': 'AB+',
      'units': '3 Units',
      'decision': 'pending',
    },
    {
      'id': 3,
      'status': 'Critical',
      'hospital': 'Civil Hospital',
      'location': 'Hospital chowk, Rajkot',
      'patient': 'Pratik Nakum',
      'bloodType': 'AB+',
      'units': '3 Units',
      'decision': 'pending',
    },
    {
      'id': 4,
      'status': 'Urgent',
      'hospital': 'Rajkot Cancer Hospital',
      'location': 'Kalawad Road, Rajkot',
      'patient': 'Neha Shah',
      'bloodType': 'B+',
      'units': '1 Unit',
      'decision': 'pending',
    },
    {
      'id': 5,
      'status': 'Critical',
      'hospital': 'H.J. Doshi Hospital',
      'location': 'University Road, Rajkot',
      'patient': 'Karan Patel',
      'bloodType': 'O+',
      'units': '2 Units',
      'decision': 'pending',
    },
  ];

  // System alerts
  static final List<Map<String, dynamic>> alerts = [
    {
      'id': 1,
      'badge': 'Normal',
      'urgency': 'Normal',
      'time': '15m ago',
      'title': 'NORMAL: NEW B+ REQUEST',
      'description':
          'Rajkot Cancer Hospital requires approval for a 1-unit B+ Normal request.',
    },
    {
      'id': 2,
      'badge': 'Urgent',
      'urgency': 'Urgent',
      'time': '15m ago',
      'title': 'URGENT: NEW B+ REQUEST',
      'description':
          'Rajkot Cancer Hospital requires approval for a 1-unit B+ Urgent request.',
    },
    {
      'id': 3,
      'badge': 'Critical',
      'urgency': 'Critical',
      'time': '15m ago',
      'title': 'CRITICAL: NEW AB+ REQUEST',
      'description':
          'Civil Hospital requires immediate approval for a 3-unit AB+ Critical request.',
    },
    {
      'id': 4,
      'badge': 'Normal',
      'urgency': 'Normal',
      'time': '32m ago',
      'title': 'NORMAL: NEW AB+ REQUEST',
      'description':
          'Civil Hospital requires approval for a 3-unit AB+ Normal request.',
    },
    {
      'id': 5,
      'badge': 'Critical',
      'urgency': 'Critical',
      'time': '1h ago',
      'title': 'CRITICAL: NEW O+ REQUEST',
      'description':
          'H.J. Doshi Hospital requires immediate approval for a 2-unit O+ Critical request.',
    },
  ];

  // Users
  static final List<Map<String, dynamic>> users = [
    {
      'id': 1,
      'name': 'Pratik Nakum',
      'email': 'Example@gmail.com',
      'role': 'AB+ Donor',
    },
    {
      'id': 2,
      'name': 'Pratik Nakum',
      'email': 'Example@gmail.com',
      'role': 'AB+ Donor',
    },
    {
      'id': 3,
      'name': 'Pratik Nakum',
      'email': 'Example@gmail.com',
      'role': 'AB+ Donor',
    },
    {
      'id': 4,
      'name': 'Pratik Nakum',
      'email': 'Example@gmail.com',
      'role': 'AB+ Donor',
    },
    {
      'id': 5,
      'name': 'Pratik Nakum',
      'email': 'Example@gmail.com',
      'role': 'AB+ Donor',
    },
    {
      'id': 6,
      'name': 'Neha Shah',
      'email': 'neha@gmail.com',
      'role': 'B+ Donor',
    },
    {
      'id': 7,
      'name': 'Karan Patel',
      'email': 'karan@gmail.com',
      'role': 'O+ Donor',
    },
  ];
}