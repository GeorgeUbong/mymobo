import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../model/card_model.dart';
import '../themes/app_themes.dart';
import '../viewmodel/app_viewmodel.dart';
import '../viewmodel/digi_widget.dart';

/// 3 steps: custom name -> card details -> colour template (last).
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _nameKey = GlobalKey<FormState>();
  final _detailsKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  int _step = 0;
  CardTemplate _template = CardTemplate.teal;
  bool _saving = false;

  static const _titles = ['Name your card', 'Card details', 'Pick a style'];

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _number, _expiry, _cvv]) {
      c.addListener(() => setState(() {})); // live preview
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  String get _digits => _number.text.replaceAll(' ', '');

  CardModel get _draft => CardModel(
    id: 'draft',
    name: _name.text.trim().isEmpty ? 'Card name' : _name.text.trim(),
    template: _template,
    number: _digits,
    cvv: _cvv.text,
    expiry: _expiry.text,
    type: CardType.detect(_digits),
  );

  Future<void> _next() async {
    if (_step == 0 && !_nameKey.currentState!.validate()) return;
    if (_step == 1 && !_detailsKey.currentState!.validate()) return;

    if (_step < 2) {
      setState(() => _step++);
      return;
    }

    setState(() => _saving = true);
    await context.read<AppViewModel>().addCard(
      name: _name.text,
      number: _number.text,
      cvv: _cvv.text,
      expiry: _expiry.text,
      template: _template,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Add card',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  DigiCardWidget(card: _draft, showDetails: _step > 0),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: (_step + 1) / 3,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Step ${_step + 1} of 3 · ${_titles[_step]}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_step) {
                      0 => _nameStep(),
                      1 => _detailsStep(scheme),
                      _ => _templateStep(),
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _saving ? null : _back,
                      child: Text(_step == 0 ? 'Cancel' : 'Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white
                      ),
                      onPressed: _saving ? null : _next,
                      child: Text(_step == 2 ? 'Save card' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameStep() => Form(
    key: _nameKey,
    child: Column(
      key: const ValueKey(0),
      children: [
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Card name',
            hintText: 'e.g. Salary card',
            prefixIcon: Icon(Icons.edit_outlined),
          ),
          validator: AppViewModel.validateCardName,
        ),
      ],
    ),
  );

  Widget _detailsStep(ColorScheme scheme) => Form(
    key: _detailsKey,
    child: Column(
      key: const ValueKey(1),
      children: [
        TextFormField(
          controller: _number,
          keyboardType: TextInputType.number,
          inputFormatters: [_CardNumberFormatter()],
          decoration: const InputDecoration(
            labelText: 'Card number',
            prefixIcon: Icon(Icons.credit_card),
          ),
          validator: AppViewModel.validateCardNumber,
        ),
        if (_digits.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Detected type: ${CardType.detect(_digits).label}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiry,
                keyboardType: TextInputType.number,
                inputFormatters: [_ExpiryFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Expiry',
                  hintText: 'MM/YY',
                ),
                validator: AppViewModel.validateExpiry,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvv,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  counterText: '',
                ),
                validator: (v) =>
                    AppViewModel.validateCvv(v, type: CardType.detect(_digits)),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _templateStep() {
    final theme = context.cardTheme;
    return Wrap(
      key: const ValueKey(2),
      spacing: 16,
      runSpacing: 16,
      children: CardTemplate.values.map((t) {
        final selected = t == _template;
        return GestureDetector(
          onTap: () => setState(() => _template = t),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 76,
                height: 52,
                decoration: BoxDecoration(
                  gradient: theme.gradientFor(t),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, color: theme.onCard)
                    : null,
              ),
              const SizedBox(height: 6),
              Text(t.name[0].toUpperCase() + t.name.substring(1)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 1234567890123456 -> 1234 5678 9012 3456
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 19) digits = digits.substring(0, 19);

    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// 1228 -> 12/28
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);

    final text = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
