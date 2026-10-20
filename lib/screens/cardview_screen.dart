import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../model/card_model.dart';
import '../viewmodel/app_viewmodel.dart';
import '../viewmodel/digi_widget.dart';

/// Shows one card. Details appear only after authentication
/// (skipped automatically when biometric protection is off).
class CardViewScreen extends StatefulWidget {
  final String cardId;
  const CardViewScreen({super.key, required this.cardId});

  @override
  State<CardViewScreen> createState() => _CardViewScreenState();
}

class _CardViewScreenState extends State<CardViewScreen> {
  late final AppViewModel _vm;
  bool _authFailed = false;

  @override
  void initState() {
    super.initState();
    _vm = context.read<AppViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    final id = widget.cardId;
    Future.microtask(() => _vm.hideCard(id)); // re-lock when leaving
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() => _authFailed = false);
    final ok = await _vm.revealCard(widget.cardId);
    if (!mounted) return;
    if (!ok) setState(() => _authFailed = true);
  }

  Future<void> _delete(CardModel card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text('"${card.name}" will be removed from this device.',),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await _vm.deleteCard(card.id);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final matches = vm.cards.where((c) => c.id == widget.cardId);
    if (matches.isEmpty) return const Scaffold();

    final card = matches.first;
    final revealed = vm.isRevealed(card.id);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(card.name,  style: GoogleFonts.lobster(textStyle: TextStyle(fontSize: 32, color: Theme.of(context).colorScheme.primary)))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DigiCardWidget(card: card, showDetails: revealed),
          const SizedBox(height: 24),
          if (revealed) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _DetailRow('Card name', card.name),
                    _DetailRow('Card number', card.formattedNumber),
                    _DetailRow('Expiry', card.expiry),
                    _DetailRow('CVV', card.cvv),
                    _DetailRow('Type', card.type.label),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('Card status'),
                subtitle: Text(card.isActive ? 'Active' : 'Inactive'),
                value: card.isActive,
                onChanged: (_) => vm.toggleCardActive(card.id),
              ),
            ),
            const SizedBox(height: 40),

            //delete card zone
           Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 252, 167),
              borderRadius: BorderRadius.circular(30)
            ),
            child:  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dangerzone', style: GoogleFonts.lobster(textStyle: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.error )),),
                SizedBox(height: 20,),

                //button
                ElevatedButton(onPressed: (){
                   _delete(card);
                }, 
                style: ElevatedButton.styleFrom(
                  elevation: 0,
  
                ),
                child: TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.delete_outline, color: scheme.error),
              label: Text('Delete card', style: TextStyle(color: scheme.error)),
            ),)
              ],
            )
           )
          ] else if (_authFailed)
            Column(
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 48, color: scheme.outline),
                const SizedBox(height: 12),
                const Text('Authenticate to view card details'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _unlock,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock'),
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}