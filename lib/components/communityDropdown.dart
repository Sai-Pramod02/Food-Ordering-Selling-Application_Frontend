// community_dropdown.dart
import 'package:flutter/material.dart';
import 'package:food_buddies/pages/ api_service.dart';

class CommunityDropdown extends StatefulWidget {
  final String? initialCommunity;
  final void Function(String?) onChanged;

  CommunityDropdown({this.initialCommunity, required this.onChanged});

  @override
  _CommunityDropdownState createState() => _CommunityDropdownState();
}

class _CommunityDropdownState extends State<CommunityDropdown> {
  String? _selectedCommunity;
  List<String> _communities = [];

  @override
  void initState() {
    super.initState();
    _fetchCommunities();
  }

  Future<void> _fetchCommunities() async {
    final communities = await APIService.fetchCommunities();
    setState(() {
      _communities = communities;
      _selectedCommunity = widget.initialCommunity ?? (communities.isNotEmpty ? communities[0] : null);
    });
  }

  @override
  void didUpdateWidget(CommunityDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCommunity != oldWidget.initialCommunity) {
      setState(() {
        _selectedCommunity = widget.initialCommunity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: 'Community'),
      value: _selectedCommunity,
      items: _communities.map((String community) {
        return DropdownMenuItem<String>(
          value: community,
          child: Text(community),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCommunity = newValue;
        });
        widget.onChanged(newValue);
      },
      validator: (value) => value == null ? 'Please select a community' : null,
    );
  }
}
