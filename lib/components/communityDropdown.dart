import 'package:flutter/material.dart';
import 'package:food_buddies/pages/ api_service.dart';

class CommunityDropdown extends StatefulWidget {
  final String? initialCommunity; // Allow initialCommunity to be nullable
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
    // Initialize _selectedCommunity in initState if initialCommunity is not null
    _selectedCommunity = widget.initialCommunity;
    print('initState: _selectedCommunity = $_selectedCommunity');
    // Fetch communities
    _fetchCommunities();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update _selectedCommunity in didChangeDependencies if initialCommunity changes
    if (widget.initialCommunity != _selectedCommunity) {
      setState(() {
        _selectedCommunity = widget.initialCommunity;
      });
      print('didChangeDependencies: _selectedCommunity updated to $_selectedCommunity');
    }
  }

  @override
  void didUpdateWidget(CommunityDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCommunity != oldWidget.initialCommunity) {
      setState(() {
        _selectedCommunity = widget.initialCommunity;
      });
      print('didUpdateWidget: _selectedCommunity updated to $_selectedCommunity');
    }
  }

  Future<void> _fetchCommunities() async {
    final communities = await APIService.fetchCommunities();
    setState(() {
      _communities = communities;
      if (_selectedCommunity != null && !_communities.contains(_selectedCommunity)) {
        _selectedCommunity = null; // Reset to null if initial community is not in fetched communities
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: 'Community'),
      value: _selectedCommunity,
      items: _communities.toSet().map((String community) {
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
