import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// 网络图片统一入口。
///
/// 云存储下载域名（*.tcb.qcloud.la）不返回 CORS 头，Flutter Web 的
/// Image.network 默认走 XHR 取字节流，跨域时必然失败（图片加载不出来）。
/// web 端启用 WebHtmlElementStrategy.fallback：XHR 失败时回退到 <img>
/// 元素渲染，浏览器加载 <img> 不受 CORS 限制；非 web 平台该参数无效，
/// 仍走默认解码。
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      webHtmlElementStrategy: kIsWeb
          ? WebHtmlElementStrategy.fallback
          : WebHtmlElementStrategy.never,
    );
  }
}
