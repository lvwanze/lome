import 'package:flutter/material.dart';

// ========== 留言板列表主页（底部Tab跳转这个）==========
class MessageBoardPage extends StatefulWidget {
  const MessageBoardPage({super.key});

  @override
  State<MessageBoardPage> createState() => _MessageBoardPageState();
}

class _MessageBoardPageState extends State<MessageBoardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EBD8),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/message_board_page.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // 顶部栏
                SizedBox(
                  height: 56,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 56,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF887770), size: 24),
                        ),
                      ),
                      const Text(
                        "留言板",
                        style: TextStyle(fontSize: 34, color: Color(0xFFB8A8A2), fontWeight: FontWeight.w400),
                      ),
                      // 加号按钮：跳转到【新建留言编辑页 NewMessagePage】
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NewMessagePage()),
                          );
                        },
                        child: Container(
                          width: 56,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.add, color: Color(0xFF887770), size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height:20),
                // 留言列表区域（后续填充真实留言）
                const Expanded(
                  child: Center(child: Text("留言列表区域，待实现", style: TextStyle(fontSize:18, color: Color(0xFF776B65)))),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ========== 新建留言编辑页（点击列表页加号跳转这里）==========
class NewMessagePage extends StatefulWidget {
  const NewMessagePage({super.key});

  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final TextEditingController _textController = TextEditingController();
  int _charCount = 0;
  // 模拟已选图片数量
  final List<int> _selectedImages = [1,2];

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _charCount = _textController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EBD8),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/message_board_page.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal:16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部栏
                SizedBox(
                  height: 56,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 返回
                      GestureDetector(
                        onTap: ()=>Navigator.pop(context),
                        child: Container(
                          width:56,
                          height:48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF887770), size:24),
                        ),
                      ),
                      const Text(
                        "新留言",
                        style: TextStyle(fontSize:34, color: Color(0xFFB8A8A2), fontWeight: FontWeight.w400),
                      ),
                      // 发送按钮
                      GestureDetector(
                        onTap: (){
                          // 发布逻辑，暂时直接返回
                          Navigator.pop(context);
                        },
                        child: Container(
                          width:56,
                          height:48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.send, color: Color(0xFF887770), size:22),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height:12),
                // 输入框区域
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.62),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              TextField(
                                controller: _textController,
                                maxLines: 6,
                                maxLength: 50,
                                style: const TextStyle(fontSize:20, color: Color(0xFF776B65)),
                                decoration: const InputDecoration(
                                  hintText: "想说的话...\n请输入文本",
                                  hintStyle: TextStyle(fontSize:20, color: Color(0xFFBCB0AA)),
                                  border: InputBorder.none,
                                  counterText: "",
                                ),
                              ),
                              // 右下角字数
                              Positioned(
                                bottom:0,
                                right:0,
                                child: Text(
                                  "$_charCount/50",
                                  style: const TextStyle(color: Color(0xFF998E88), fontSize:16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height:24),
                        // 添加图片 + 情绪标签按钮行
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height:72,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_outlined, size:26, color: Color(0xFFAA9890)),
                                    SizedBox(width:8),
                                    Text("添加图片", style: TextStyle(fontSize:18, color: Color(0xFF94847D))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width:16),
                            Expanded(
                              child: Container(
                                height:72,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.sentiment_satisfied_alt_outlined, size:26, color: Color(0xFFAA9890)),
                                    SizedBox(width:8),
                                    Text("情绪标签", style: TextStyle(fontSize:18, color: Color(0xFF94847D))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height:16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("已选图片 2/2", style: TextStyle(fontSize:16, color: Color(0xFF94847D))),
                        ),
                        const SizedBox(height:12),
                        // 图片预览卡片
                        SizedBox(
                          height:240,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            separatorBuilder: (_,__)=>const SizedBox(width:14),
                            itemBuilder: (ctx, index){
                              return Stack(
                                children: [
                                  Container(
                                    width:180,
                                    height:240,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  Positioned(
                                    top:8,
                                    right:8,
                                    child: GestureDetector(
                                      onTap: (){
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        width:32,
                                        height:32,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE8E2DD),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size:18, color: Color(0xFF94847D)),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height:24),
                        // 情绪标签标题
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("情绪标签", style: TextStyle(fontSize:22, color: Color(0xFF776B65), fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height:14),
                        // 情绪标签按钮组
                        Wrap(
                          spacing:12,
                          runSpacing:12,
                          children: const [
                            _EmotionChip(icon: Icons.sentiment_satisfied, label:"开心"),
                            _EmotionChip(icon: Icons.eco_outlined, label:"思念"),
                            _EmotionChip(icon: Icons.nightlight_outlined, label:"晚安"),
                            _EmotionChip(icon: Icons.favorite_border, label:"求抱抱"),
                          ],
                        ),
                        const SizedBox(height:40),
                        // 底部草稿提示
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_done_outlined, size:20, color: Color(0xFF887770)),
                            SizedBox(width:6),
                            Text("草稿已自动保存", style: TextStyle(fontSize:16, color: Color(0xFF887770))),
                          ],
                        ),
                        const SizedBox(height:20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmotionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmotionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:22, vertical:10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size:20, color: Color(0xFF94847D)),
          const SizedBox(width:6),
          Text(label, style: TextStyle(fontSize:17, color: Color(0xFF776B65))),
        ],
      ),
    );
  }
}
