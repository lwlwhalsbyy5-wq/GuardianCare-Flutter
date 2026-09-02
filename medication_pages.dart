// ignore_for_file: deprecated_member_use 
 
 
 
import 'package:flutter/material.dart'; 
 
class MedicationSubmission { 
  final String name; 
  final String schedule; 
 
  MedicationSubmission({ 
    required this.name, 
    required this.schedule, 
  }); 
} 
 
class MedicationEntryPage extends StatefulWidget { 
  static const String routeName = '/medicationEntry'; 
 
  const MedicationEntryPage({super.key}); 
 
  @override 
  State<MedicationEntryPage> createState() => 
_MedicationEntryPageState(); 
} 
 
class _MedicationEntryPageState extends State<MedicationEntryPage> { 
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); 
  final TextEditingController _nameController = 
TextEditingController(); 
  String _selectedHabit = 'After Breakfast'; 
  final List<String> _habitOptions = [ 
    'After Breakfast', 
    'After Lunch', 
    'After Dinner', 
  ]; 
 
  @override 
  void dispose() { 
    _nameController.dispose(); 
    super.dispose(); 
  } 
 
  void _saveMedication() { 
    if (!_formKey.currentState!.validate()) { 
      return; 
    } 
    _showSuccessDialog(); 
  } 
 
  void _showSuccessDialog() { 
    final submission = MedicationSubmission( 
      name: _nameController.text.trim(), 
      schedule: _selectedHabit, 
    ); 
 
    showDialog<void>( 
      context: context, 
      barrierDismissible: false, 
      builder: (context) { 
        return Dialog( 
          shape: RoundedRectangleBorder( 
            borderRadius: BorderRadius.circular(25), 
          ), 
          child: Padding( 
            padding: const EdgeInsets.symmetric(horizontal: 24, 
vertical: 24), 
            child: Stack( 
              children: [ 
                Column( 
                  mainAxisSize: MainAxisSize.min, 
                  children: [ 
                    const SizedBox(height: 16), 
                    Container( 
                      height: 96, 
                      width: 96, 
                      decoration: BoxDecoration( 
                        color: const Color(0xFFD4E9D0), 
                        shape: BoxShape.circle, 
                      ), 
                      child: const Center( 
                        child: Icon( 
                          Icons.check, 
                          size: 48, 
                          color: Color(0xFF5A8F52), 
                        ), 
                      ), 
                    ), 
                    const SizedBox(height: 24), 
                    const Text( 
                      'Added Successfully', 
                      textAlign: TextAlign.center, 
                      style: TextStyle( 
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                      ), 
                    ), 
                    const SizedBox(height: 12), 
                    const Text( 
                      'Your medication has been added to your list.', 
                      textAlign: TextAlign.center, 
                      style: TextStyle(fontSize: 15, color: 
Colors.grey), 
                    ), 
                    const SizedBox(height: 28), 
                    SizedBox( 
                      width: double.infinity, 
                      child: ElevatedButton( 
                        onPressed: () { 
                          Navigator.of(context).pop(); 
                          Navigator.of(this.context).pop(submission); 
                        }, 
                        style: ElevatedButton.styleFrom( 
                          backgroundColor: Colors.black, 
                          shape: RoundedRectangleBorder( 
                            borderRadius: BorderRadius.circular(15), 
                          ), 
                          padding: const EdgeInsets.symmetric(vertical: 
16), 
                        ), 
                        child: const Text( 
                          'Continue', 
                          style: TextStyle(fontSize: 16), 
                        ), 
                      ), 
                    ), 
                  ], 
                ), 
                Positioned( 
                  top: 0, 
                  right: 0, 
                  child: IconButton( 
                    splashRadius: 20, 
                    icon: const Icon(Icons.close, color: Colors.grey), 
                    onPressed: () { 
                      Navigator.of(context).pop(); 
                    }, 
                  ), 
                ), 
              ], 
            ), 
          ), 
        ); 
      }, 
    ); 
  } 
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      backgroundColor: const Color(0xFFF6F5F2), 
      appBar: AppBar( 
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        title: const Text( 
          'Add Medication', 
          style: TextStyle(color: Colors.black87), 
        ), 
        iconTheme: const IconThemeData(color: Colors.black87), 
      ), 
      body: SingleChildScrollView( 
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 
24), 
        child: Form( 
          key: _formKey, 
          child: Column( 
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [ 
              Container( 
                decoration: BoxDecoration( 
                  color: const Color(0xFFEEECE4), 
                  borderRadius: BorderRadius.circular(20), 
                ), 
                padding: const EdgeInsets.all(20), 
                child: Column( 
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [ 
                    const Text( 
                      'Pill Verification (Optional)', 
                      style: TextStyle( 
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                      ), 
                    ), 
                    const SizedBox(height: 16), 
                    Container( 
                      width: double.infinity, 
                      padding: const EdgeInsets.symmetric( 
                        horizontal: 16, 
                        vertical: 30, 
                      ), 
                      decoration: BoxDecoration( 
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(18), 
                      ), 
                      child: Column( 
                        mainAxisSize: MainAxisSize.min, 
                        // ... keep your existing Column children here 
                      ), 
                    ), 
                  ], 
                ), 
              ), 
              const SizedBox(height: 24), 
              TextFormField( 
                controller: _nameController, 
                decoration: InputDecoration( 
                  labelText: 'Medication Name', 
                  filled: true, 
                  fillColor: const Color(0xFFEEECE4), 
                  prefixIcon: const Icon( 
                    Icons.medication_outlined, 
                    color: Color(0xFF5A8F52), 
                  ), 
                  enabledBorder: OutlineInputBorder( 
                    borderRadius: BorderRadius.circular(18), 
                    borderSide: 
                        const BorderSide(color: Color(0xFF88AF81), 
width: 1.8), 
                  ), 
                  focusedBorder: OutlineInputBorder( 
                    borderRadius: BorderRadius.circular(18), 
                    borderSide: 
                        const BorderSide(color: Color(0xFF88AF81), 
width: 2), 
                  ), 
                  contentPadding: 
                      const EdgeInsets.symmetric(horizontal: 16, 
vertical: 20), 
                ), 
                validator: (value) { 
                  if (value == null || value.trim().isEmpty) { 
                    return 'Please enter the medication name.'; 
                  } 
                  return null; 
                }, 
              ), 
              const SizedBox(height: 24), 
              const Text( 
                'When do you take it?', 
                style: TextStyle(fontSize: 16, fontWeight: 
FontWeight.w600), 
              ), 
              const SizedBox(height: 14), 
              Column( 
                children: _habitOptions.map((habit) { 
                  final bool selected = _selectedHabit == habit; 
                  return Padding( 
                    padding: const EdgeInsets.only(bottom: 12), 
                    child: InkWell( 
                      onTap: () { 
                        setState(() { 
                          _selectedHabit = habit; 
                        }); 
                      }, 
                      borderRadius: BorderRadius.circular(18), 
                      child: Container( 
                        decoration: BoxDecoration( 
                          color: selected 
                              ? const Color(0xFFE6F0E4) 
                              : Colors.white, 
                          borderRadius: BorderRadius.circular(18), 
                          border: Border.all( 
                            color: selected 
                                ? const Color(0xFF5A8F52) 
                                : Colors.grey.shade300, 
                            width: selected ? 1.8 : 1, 
                          ), 
                          boxShadow: [ 
                            BoxShadow( 
                              color: Colors.black.withOpacity(0.02), 
                              blurRadius: 8, 
                              spreadRadius: 1, 
                              offset: const Offset(0, 3), 
                            ), 
                          ], 
                        ), 
                        padding: const EdgeInsets.symmetric( 
                          horizontal: 16, 
                          vertical: 18, 
                        ), 
                        child: Row( 
                          children: [ 
                            Container( 
                              height: 20, 
                              width: 20, 
                              decoration: BoxDecoration( 
                                shape: BoxShape.circle, 
                                border: Border.all( 
                                  color: selected 
                                      ? const Color(0xFF5A8F52) 
                                      : Colors.grey, 
                                  width: 2, 
                                ), 
                                color: selected 
                                    ? const Color(0xFF5A8F52) 
                                    : Colors.transparent, 
                              ), 
                              child: selected 
                                  ? const Icon( 
                                      Icons.check, 
                                      size: 12, 
                                      color: Colors.white, 
                                    ) 
                                  : null, 
                            ), 
                            const SizedBox(width: 14), 
                            Text( 
                              habit, 
                              style: TextStyle( 
                                fontSize: 16, 
                                fontWeight: selected 
                                    ? FontWeight.w700 
                                    : FontWeight.w500, 
                                color: selected 
                                    ? const Color(0xFF305C2F) 
                                    : Colors.black87, 
                              ), 
                            ), 
                          ], 
                        ), 
                      ), 
                    ), 
                  ); 
                }).toList(), 
              ), 
              const SizedBox(height: 32), 
              ElevatedButton( 
                onPressed: _saveMedication, 
                style: ElevatedButton.styleFrom( 
                  backgroundColor: Colors.black, 
                  shape: RoundedRectangleBorder( 
                    borderRadius: BorderRadius.circular(15), 
                  ), 
                  padding: const EdgeInsets.symmetric(vertical: 18), 
                ), 
                child: const Text( 
                  'Add Medication', 
                  style: TextStyle(fontSize: 16, fontWeight: 
FontWeight.bold), 
                ), 
              ), 
              const SizedBox(height: 16), 
const Text( 
'"Never miss a dose or follow-up — Guardiancare App keeps you on track."', 
textAlign: TextAlign.center, 
style: TextStyle( 
fontSize: 14, 
color: Colors.black54, 
fontStyle: FontStyle.italic, 
), 
), 
const SizedBox(height: 24), 
], 
), 
), 
), 
); 
} 
}