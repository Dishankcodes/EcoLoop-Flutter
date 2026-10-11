import 'package:flutter/material.dart';
import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';

class ReviewHistory extends StatefulWidget {
  const ReviewHistory({super.key});
  @override
  State<ReviewHistory> createState() => _ReviewHistoryState();
}

class _ReviewHistoryState extends State<ReviewHistory> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  List<Map<String,dynamic>> _reviews = [];
  int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await EcoLoopApi.instance.get('/my/reviews');
      final rows = data is List ? data : (data is Map && data['reviews'] is List ? data['reviews'] as List : <dynamic>[]);
      if (!mounted) return;
      setState(() { _reviews = rows.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList(); _loading = false; });
    } catch(e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }
  bool _isSellerReview(Map<String,dynamic> r) => '${r['reviewType'] ?? ''}' == 'seller' || (r['artistId'] != null && '${r['productId'] ?? ''}'.isEmpty);
  List<Map<String,dynamic>> get _visible => _reviews.where((r) => _tab == 0 ? !_isSellerReview(r) : _isSellerReview(r)).toList()
    ..sort((a,b) => (DateTime.tryParse('${b['createdAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(DateTime.tryParse('${a['createdAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('My Reviews'), backgroundColor: AppColors.surface, foregroundColor: AppColors.textPrimary, elevation: 0),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: SegmentedButton<int>(segments: const [ButtonSegment(value:0,label:Text('Products')),ButtonSegment(value:1,label:Text('Sellers'))], selected: {_tab}, onSelectionChanged: (v)=>setState(()=>_tab=v.first))),
      Expanded(child: RefreshIndicator(onRefresh:_load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16,0,16,24), children: [
        if (_loading) const Padding(padding: EdgeInsets.all(28), child: Center(child:CircularProgressIndicator()))
        else if (_error != null) _empty(_error!, retry:_load)
        else if (_visible.isEmpty) _empty(_tab == 0 ? 'You have not written any product reviews yet.' : 'You have not written any seller reviews yet.')
        else ..._visible.map((r) => Container(margin: const EdgeInsets.only(bottom:12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(15)), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: [
          Row(children:[Expanded(child:Text('${_tab == 0 ? (r['productTitle'] ?? 'Product') : (r['sellerName'] ?? 'Seller')}', style:const TextStyle(fontWeight:FontWeight.w700))), Text('${_int(r['rating'])} ★',style:const TextStyle(color:AppColors.primary,fontWeight:FontWeight.w700))]),
          const SizedBox(height:6), Text('${r['createdAt'] ?? ''}',style:const TextStyle(fontSize:11,color:AppColors.textSecondary)),
          const SizedBox(height:8), Text('${r['comment'] ?? ''}'),
        ]))),
      ]))),
    ]),
  );
  Widget _empty(String text,{Future<void> Function()? retry}) => Padding(padding:const EdgeInsets.all(24),child:Column(children:[const Icon(Icons.rate_review_outlined,size:36,color:AppColors.textSecondary),const SizedBox(height:8),Text(text,textAlign:TextAlign.center),if(retry!=null)TextButton(onPressed:retry,child:const Text('Try again'))]));
}
