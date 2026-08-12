import 'package:flutter/material.dart';

class AddRecordPage extends StatelessWidget {
  const AddRecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/calendar_plan_bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 返回 + 标题栏
                SizedBox(
                  height: 60,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3,
                              )
                            ],
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xff888888)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "添加记录",
                          style: TextStyle(
                            fontSize: 36,
                            color: Color(0xffC8B8C2),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 8, thickness: 4, color: Color(0xffD9E8ED)),
                const SizedBox(height: 24),

                // 记录时间
                _buildInputCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: const Text("记录时间", style: TextStyle(fontSize: 18, color: Color(0xff887882))),
                    subtitle: const Text(
                      "0000年00月00日·周一  00: 00",
                      style: TextStyle(fontSize: 17, color: Color(0xffC9C0C6)),
                    ),
                    trailing: const Icon(Icons.keyboard_arrow_right, color: Color(0xffC9C0C6), size: 24),
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 16),

                // 记录标题
                _buildInputCard(
                  child: TextField(
                    style: const TextStyle(fontSize: 18, color: Color(0xff665862)),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal:16, vertical:14),
                      border: InputBorder.none,
                      hintText: "和TA一起做了什么",
                      hintStyle: TextStyle(fontSize:17, color: Color(0xffC9C0C6)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 记录备注
                _buildInputCard(
                  child: Stack(
                    children: [
                      TextField(
                        maxLines: 6,
                        maxLength: 500,
                        style: const TextStyle(fontSize: 17, color: Color(0xff665862)),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal:16, vertical:14),
                          border: InputBorder.none,
                          hintText: "写下故事的细节……",
                          hintStyle: TextStyle(fontSize:17, color: Color(0xffC9C0C6)),
                        ),
                      ),
                      const Positioned(
                        bottom: 10,
                        right:14,
                        child: Text("0/500", style: TextStyle(color: Color(0xffC9C0C6), fontSize:16)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 添加图片
                _buildInputCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("添加图片", style: TextStyle(fontSize:18, color: Color(0xff887882))),
                            Text("最多4张", style: TextStyle(fontSize:16, color: Color(0xff998892))),
                          ],
                        ),
                        const SizedBox(height:12),
                        Row(
                          children: [
                            _buildImageBox(),
                            const SizedBox(width:10),
                            _buildImageBox(),
                            const SizedBox(width:10),
                            _buildImageBox(),
                            const SizedBox(width:10),
                            _buildAddImageBox(),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 保存记录按钮 浅粉色
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffF8D2DC),
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    onPressed: () {
                      // 仅弹出提示，页面不跳转停留
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("保存成功"),
                          backgroundColor: Color(0xff68A878),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text("保存记录", style: TextStyle(fontSize:20, color: Colors.white)),
                  ),
                ),
                const SizedBox(height:14),

                // 取消可点击返回
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "取消",
                      style: TextStyle(fontSize:18, color: Color(0xffB4C8BB)),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({required Widget child}){
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius:4)],
      ),
      child: child,
    );
  }

  Widget _buildImageBox(){
    return SizedBox(
      width: 78,
      height:78,
      child: Stack(
        children: [
          Container(
            width:78, height:78,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffdddddd), width:1),
            ),
          ),
          Positioned(
            top:4, right:4,
            child: Container(
              width:20, height:20,
              decoration: BoxDecoration(color: const Color(0xffcccccc), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.close, size:14, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAddImageBox(){
    return SizedBox(
      width:78, height:78,
      child: Container(
        width:78, height:78,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffD0E2E8), width:1),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size:28, color: Color(0xffB4D2D9)),
            SizedBox(height: 2),
            Text("添加", style: TextStyle(fontSize:14, color: Color(0xff94B8C0))),
          ],
        ),
      ),
    );
  }
}