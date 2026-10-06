/// Local dummy data for the Admin Panel.
/// Replace with a backend later.

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

  // ---------------------------------------------------------
  // DONORS
  // ---------------------------------------------------------

  static final List<Map<String, dynamic>> donors = [
    {
      'id': 1,
      'name': 'Pratik Nakum',
      'location': 'Raiya Road, Rajkot',
      'bloodType': 'AB+',
      'eligibility': 'Ready',
      'lastDonation': 'January 14, 2026',
      'totalDonations': '3 Times',
    },
    {
      'id': 2,
      'name': 'Karan Patel',
      'location': 'Kalawad Road, Rajkot',
      'bloodType': 'O+',
      'eligibility': 'Ready',
      'lastDonation': 'December 20, 2025',
      'totalDonations': '5 Times',
    },
    {
      'id': 3,
      'name': 'Neha Shah',
      'location': 'University Road, Rajkot',
      'bloodType': 'B+',
      'eligibility': 'Not Ready',
      'lastDonation': 'February 05, 2026',
      'totalDonations': '2 Times',
    },
    {
      'id': 4,
      'name': 'Amit Joshi',
      'location': 'Yagnik Road, Rajkot',
      'bloodType': 'A+',
      'eligibility': 'Ready',
      'lastDonation': 'January 25, 2026',
      'totalDonations': '4 Times',
    },
    {
      'id': 5,
      'name': 'Riya Mehta',
      'location': 'Mavdi, Rajkot',
      'bloodType': 'AB-',
      'eligibility': 'Ready',
      'lastDonation': 'November 18, 2025',
      'totalDonations': '2 Times',
    },
  ];

  // ---------------------------------------------------------
  // BLOOD REQUESTS
  // ---------------------------------------------------------

  static final List<Map<String, dynamic>> requests = [
    {
      'id': 1,
      'status': 'Normal',
      'hospital': 'Civil Hospital',
      'location': 'Hospital Chowk, Rajkot',
      'patient': 'Pratik Nakum',
      'bloodType': 'AB+',
      'units': '3 Units',
      'decision': 'pending',
    },
    {
      'id': 2,
      'status': 'Urgent',
      'hospital': 'Civil Hospital',
      'location': 'Hospital Chowk, Rajkot',
      'patient': 'Neha Shah',
      'bloodType': 'B+',
      'units': '2 Units',
      'decision': 'pending',
    },
    {
      'id': 3,
      'status': 'Critical',
      'hospital': 'Rajkot Cancer Hospital',
      'location': 'Kalawad Road, Rajkot',
      'patient': 'Karan Patel',
      'bloodType': 'O+',
      'units': '4 Units',
      'decision': 'pending',
    },
    {
      'id': 4,
      'status': 'Normal',
      'hospital': 'H.J. Doshi Hospital',
      'location': 'University Road, Rajkot',
      'patient': 'Amit Joshi',
      'bloodType': 'A+',
      'units': '1 Unit',
      'decision': 'pending',
    },
    {
      'id': 5,
      'status': 'Critical',
      'hospital': 'Civil Hospital',
      'location': 'Hospital Chowk, Rajkot',
      'patient': 'Riya Mehta',
      'bloodType': 'AB-',
      'units': '3 Units',
      'decision': 'pending',
    },
  ];

  // ---------------------------------------------------------
  // SYSTEM ALERTS
  // ---------------------------------------------------------

  static final List<Map<String, dynamic>> alerts = [
    {
      'id': 1,
      'badge': 'Normal',
      'time': '15m ago',
      'title': 'NORMAL: NEW B+ REQUEST',
      'description':
          'Rajkot Cancer Hospital requires approval for a 1-unit B+ Normal request.',
    },
    {
      'id': 2,
      'badge': 'Urgent',
      'time': '20m ago',
      'title': 'URGENT: NEW O+ REQUEST',
      'description':
          'Civil Hospital requires approval for a 2-unit O+ urgent request.',
    },
    {
      'id': 3,
      'badge': 'Critical',
      'time': '25m ago',
      'title': 'CRITICAL: NEW AB- REQUEST',
      'description':
          'Rajkot Cancer Hospital requires immediate approval for a 3-unit AB- critical request.',
    },
    {
      'id': 4,
      'badge': 'Normal',
      'time': '32m ago',
      'title': 'NORMAL: NEW AB+ REQUEST',
      'description':
          'Civil Hospital requires approval for a 3-unit AB+ normal request.',
    },
    {
      'id': 5,
      'badge': 'Critical',
      'time': '1h ago',
      'title': 'CRITICAL: NEW A+ REQUEST',
      'description':
          'H.J. Doshi Hospital requires immediate approval for a 4-unit A+ critical request.',
    },
  ];

  // ---------------------------------------------------------
  // USERS
  // ---------------------------------------------------------

  static final List<Map<String, dynamic>> users = [
    {
      'id': 1,
      'name': 'Pratik Nakum',
      'email': 'pratik@gmail.com',
      'bloodGroup': 'AB+',
      'role': 'AB+ Donor',

      // Donation details
      'lastDonation': 'January 14, 2026',
      'totalDonations': '3 Times',
      'donationUnits': 2.5,
      'donationDate': 'January 14, 2026',
      'donationHospital': 'Civil Hospital',
    },
    {
      'id': 2,
      'name': 'Karan Patel',
      'email': 'karan@gmail.com',
      'bloodGroup': 'O+',
      'role': 'O+ Donor',

      'lastDonation': 'December 20, 2025',
      'totalDonations': '5 Times',
      'donationUnits': 2.0,
      'donationDate': 'December 20, 2025',
      'donationHospital': 'H.J. Doshi Hospital',
    },
    {
      'id': 3,
      'name': 'Neha Shah',
      'email': 'neha@gmail.com',
      'bloodGroup': 'B+',
      'role': 'B+ Donor',

      'lastDonation': 'February 05, 2026',
      'totalDonations': '2 Times',
      'donationUnits': 2.5,
      'donationDate': 'February 05, 2026',
      'donationHospital': 'Rajkot Cancer Hospital',
    },
    {
      'id': 4,
      'name': 'Amit Joshi',
      'email': 'amit@gmail.com',
      'bloodGroup': 'A+',
      'role': 'A+ Donor',

      'lastDonation': 'January 25, 2026',
      'totalDonations': '4 Times',
      'donationUnits': 2.0,
      'donationDate': 'January 25, 2026',
      'donationHospital': 'Civil Hospital',
    },
    {
      'id': 5,
      'name': 'Riya Mehta',
      'email': 'riya@gmail.com',
      'bloodGroup': 'AB-',
      'role': 'AB- Donor',

      'lastDonation': 'November 18, 2025',
      'totalDonations': '2 Times',
      'donationUnits': 2.5,
      'donationDate': 'November 18, 2025',
      'donationHospital': 'Civil Hospital',
    },
  ];
}