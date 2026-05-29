import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/sd_button.dart';
import 'gacha_result_screen.dart';
import '../../core/services/firebase_service.dart';

// ── Gacha item model ─────────────────────────────────────────────────────────

class GachaItem {
  final String name;
  final String emoji;
  final String rarity; // common, rare, epic, legendary, mythical
  final Color color;
  final String category; // skin, background, effect
  final String id;
  final bool isEquipped;
  final String originalType;

  const GachaItem({
    required this.name,
    required this.emoji,
    required this.rarity,
    required this.color,
    required this.category,
    this.id = '',
    this.isEquipped = false,
    this.originalType = '',
  });
}


// ── Gacha Screen (Toko) ──────────────────────────────────────────────────────

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _pullGachaAction(BuildContext context, int count, int currentTickets, int currentGems) async {
    if (currentTickets < count) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket tidak cukup!')),
      );
      return;
    }
    
    final uid = FirebaseService().currentUser?.uid;
    if (uid == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
    );

    try {
      final newTickets = currentTickets - count;
      await FirebaseService().updateUserField(uid, {'tickets': newTickets});

      final List<Map<String, dynamic>> pulled = await FirebaseService().pullGacha(
        bannerId: 'default_banner',
        bannerName: 'Cosmic Gacha',
        cost: 0,
        pullCount: count,
      );

      if (context.mounted) Navigator.of(context).pop(); // dismiss loader

      final results = pulled.map((item) {
        final rarityStr = (item['rarity'] as String).toLowerCase();
        Color c = AppColors.rarityCommon;
        if (rarityStr == 'rare') c = AppColors.rarityRare;
        if (rarityStr == 'epic') c = AppColors.rarityEpic;
        if (rarityStr == 'legendary') c = AppColors.rarityLegendary;
        if (rarityStr == 'mythical') c = AppColors.rarityMythical;

        return GachaItem(
          name: item['item_name'] ?? 'Item',
          emoji: item['item_image'] ?? '🎁',
          rarity: rarityStr,
          color: c,
          category: item['item_type'] ?? 'skin',
        );
      }).toList();

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GachaResultScreen(results: results),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal Gacha: $e')),
        );
      }
    }
  }

  void _buyTicketsAction(BuildContext context, int count, int cost, int currentGems, int currentTickets) async {
    final uid = FirebaseService().currentUser?.uid;
    if (uid == null) return;

    if (currentGems < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gems tidak cukup!')),
      );
      return;
    }

    try {
      final newGems = currentGems - cost;
      final newTickets = currentTickets + count;
      await FirebaseService().updateUserField(uid, {
        'gems': newGems,
        'tickets': newTickets,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil membeli $count tiket!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membeli tiket: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService().currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService().getUserStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.darkNavy,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data!.data() ?? {};
        final tickets = userData['tickets'] ?? 0;
        final gems = userData['gems'] ?? 0;
        final epicPity = userData['gacha_pity_epic'] ?? 0;
        final legendaryPity = userData['gacha_pity_legendary'] ?? 0;

        return Scaffold(
          backgroundColor: AppColors.darkNavy,
          appBar: AppBar(
            backgroundColor: AppColors.darkNavy,
            title: Text('Toko', style: AppTextStyles.h3.copyWith(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              Row(
                children: [
                  _CurrencyChip(icon: '🎟️', value: '$tickets'),
                  const SizedBox(width: 8),
                  _CurrencyChip(icon: '💎', value: '$gems'),
                  const SizedBox(width: 12),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tab,
              indicatorColor: AppColors.primary,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: AppTextStyles.label,
              tabs: const [
                Tab(text: 'Tiket'),
                Tab(text: 'Gacha'),
                Tab(text: 'Milikku'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _TicketTab(
                gems: gems,
                onBuy: (count, cost) => _buyTicketsAction(context, count, cost, gems, tickets),
              ),
              _GachaTab(
                tickets: tickets,
                epicPity: epicPity,
                legendaryPity: legendaryPity,
                onPull1: () => _pullGachaAction(context, 1, tickets, gems),
                onPull10: () => _pullGachaAction(context, 10, tickets, gems),
              ),
              _CollectionTab(uid: uid),
            ],
          ),
        );
      },
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final String icon, value;
  const _CurrencyChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(value, style: AppTextStyles.label.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

// ── Ticket Tab ───────────────────────────────────────────────────────────────

class _TicketTab extends StatelessWidget {
  final int gems;
  final void Function(int count, int cost) onBuy;

  const _TicketTab({required this.gems, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final packages = [
      {'count': 1, 'cost': 100, 'label': '1 Tiket', 'emoji': '🎟️', 'bonus': ''},
      {'count': 3, 'cost': 280, 'label': '3 Tiket', 'emoji': '🎟️🎟️', 'bonus': 'Hemat 20!'},
      {'count': 10, 'cost': 850, 'label': '10 Tiket', 'emoji': '🎟️✨', 'bonus': 'Hemat 150!'},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkNavyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              const Text('ℹ️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gunakan Tiket untuk bermain Gacha dan dapatkan item eksklusif!',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 24),
        ...packages.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkNavyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Text(p['emoji'] as String,
                    style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['label'] as String,
                          style: AppTextStyles.h3.copyWith(color: Colors.white)),
                      if ((p['bonus'] as String).isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(p['bonus'] as String,
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onBuy(p['count'] as int, p['cost'] as int),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('💎', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text('${p['cost']}',
                            style: AppTextStyles.label.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().slideX(begin: 0.1, delay: Duration(milliseconds: 80 * packages.indexOf(p)), duration: 300.ms),
        )),
      ],
    );
  }
}

// ── Gacha Tab ────────────────────────────────────────────────────────────────

class _GachaTab extends StatelessWidget {
  final int tickets;
  final int epicPity;
  final int legendaryPity;
  final VoidCallback onPull1, onPull10;

  const _GachaTab({
    required this.tickets,
    required this.epicPity,
    required this.legendaryPity,
    required this.onPull1,
    required this.onPull10,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF1a0533), Color(0xFF4a0a7a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(6, (i) => Positioned(
                  left: (i * 50.0) % 300,
                  top: (i * 30.0) % 180,
                  child: Text(
                    ['⭐', '✨', '💫', '🌟', '⚡', '💥'][i],
                    style: const TextStyle(fontSize: 20),
                  ),
                )),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎰', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 8),
                    Text(
                      'Cosmic Gacha',
                      style: AppTextStyles.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Dapatkan item langka!',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().scale(duration: 400.ms),

          const SizedBox(height: 16),

          // Pity progress bars
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkNavyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistem Pity Gacha 🎰',
                  style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Jaminan Epic (10 Pulls)', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                    Text('$epicPity/10', style: AppTextStyles.caption.copyWith(color: AppColors.rarityEpic, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: epicPity / 10,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(AppColors.rarityEpic),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Jaminan Legendary (50 Pulls)', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                    Text('$legendaryPity/50', style: AppTextStyles.caption.copyWith(color: AppColors.rarityLegendary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: legendaryPity / 50,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(AppColors.rarityLegendary),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkNavyCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tingkat Kemunculan',
                    style: AppTextStyles.label.copyWith(color: Colors.white)),
                const SizedBox(height: 10),
                _RateRow(label: 'Mythical', emoji: '🌌', rate: '2%', color: AppColors.rarityMythical),
                _RateRow(label: 'Legendary', emoji: '☀️', rate: '5%', color: AppColors.rarityLegendary),
                _RateRow(label: 'Epic', emoji: '💜', rate: '13%', color: AppColors.rarityEpic),
                _RateRow(label: 'Rare', emoji: '💙', rate: '30%', color: AppColors.rarityRare),
                _RateRow(label: 'Common', emoji: '⬜', rate: '50%', color: AppColors.rarityCommon),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: SdButton(
                  label: '1x Pull 🎟️',
                  variant: SdButtonVariant.outline,
                  onPressed: onPull1,
                  height: 52,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SdButton(
                  label: '10x Pull 🎟️',
                  onPressed: onPull10,
                  height: 52,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 8),
          Text(
            'Kamu punya $tickets tiket',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () async {
              final uid = FirebaseService().currentUser?.uid;
              if (uid != null) {
                await FirebaseService().updateUserField(uid, {'tickets': tickets + 50});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Berhasil menambahkan +50 Tiket Gratis! 🎉'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFC107)),
            label: Text(
              'Butuh tiket tambahan? Dapatkan 50 Tiket Gratis',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFFFFC107),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  final String label, emoji, rate;
  final Color color;
  const _RateRow({required this.label, required this.emoji, required this.rate, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(rate, style: AppTextStyles.bodySmall.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}

// ── Collection Tab ────────────────────────────────────────────────────────────

class _CollectionTab extends StatefulWidget {
  final String uid;
  const _CollectionTab({required this.uid});

  @override
  State<_CollectionTab> createState() => _CollectionTabState();
}

class _CollectionTabState extends State<_CollectionTab> {
  String _activeFilter = 'skin'; // skin | background | effect

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService().getUserInventory(widget.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)));
        }

        final docs = snapshot.data!.docs;
        
        final allItems = docs.map((doc) {
          final data = doc.data();
          final rarityStr = (data['rarity'] ?? 'common').toLowerCase();
          Color c = AppColors.rarityCommon;
          if (rarityStr == 'rare') c = AppColors.rarityRare;
          if (rarityStr == 'epic') c = AppColors.rarityEpic;
          if (rarityStr == 'legendary') c = AppColors.rarityLegendary;
          if (rarityStr == 'mythical') c = AppColors.rarityMythical;

          String type = data['item_type'] ?? 'skin';
          String category = type;
          if (category == 'avatar') category = 'skin';

          return GachaItem(
            id: doc.id,
            name: data['item_name'] ?? 'Item',
            emoji: data['item_image'] ?? '🎁',
            rarity: rarityStr,
            color: c,
            category: category,
            isEquipped: data['is_equipped'] ?? false,
            originalType: type,
          );
        }).toList();

        // Filter items
        final filteredItems = allItems.where((item) => item.category.toLowerCase() == _activeFilter).toList();

        // Separate equipped and remaining collection
        final GachaItem? equippedItem = filteredItems.cast<GachaItem?>().firstWhere(
          (item) => item != null && item.isEquipped,
          orElse: () => null,
        );

        final collectionItems = filteredItems.where((item) => !item.isEquipped).toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    {'id': 'skin', 'label': 'Skin'},
                    {'id': 'background', 'label': 'Background'},
                    {'id': 'effect', 'label': 'Effect'},
                  ].map((t) {
                    final isSelected = t['id'] == _activeFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeFilter = t['id']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.darkNavyCard,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: isSelected ? AppColors.primary : Colors.white12),
                          ),
                          child: Text(t['label']!,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Terpasang Header & Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Terpasang',
                  style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              if (equippedItem != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavyCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: equippedItem.color.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(color: equippedItem.color, width: 2),
                        ),
                        child: Center(
                          child: Text(equippedItem.emoji, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equippedItem.name,
                              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              equippedItem.rarity.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(color: equippedItem.color, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success, width: 1),
                        ),
                        child: Text(
                          'Terpasang',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.darkNavyCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    'Tidak ada $_activeFilter yang terpasang',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white38),
                  ),
                ),
              const SizedBox(height: 24),

              // Koleksi Header & Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Koleksi (${collectionItems.length})',
                  style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              if (collectionItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📦', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Koleksi $_activeFilter Anda kosong!',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: collectionItems.length,
                  itemBuilder: (_, i) {
                    final item = collectionItems[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkNavyCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: item.color.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.emoji, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              item.name,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: item.color, width: 0.5),
                            ),
                            child: Text(
                              item.rarity.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: item.color,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () async {
                              try {
                                await FirebaseService().equipItem(item.id, item.originalType);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${item.name} berhasil dipasang! 🎉'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal memasang item: $e'),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF52B788),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'pasang',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate()
                            .fadeIn(delay: Duration(milliseconds: 80 * i))
                            .scale(delay: Duration(milliseconds: 80 * i), duration: 300.ms);
                      },
                    ),
              ],
            ),
          );
      },
    );
  }
}
