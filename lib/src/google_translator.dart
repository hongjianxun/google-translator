import 'dart:async';

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:translator/src/langs/languages.dart';

import './tokens/token_provider_interface.dart';

///
/// This library is a Dart implementation of Free Google Translate API
/// based on JavaScript and PHP Free Google Translate APIs
///
/// [author] Gabriel N. Pacheco.
///
class GoogleTranslator {
  GoogleTranslator();

  // var _baseUrl = 'https://translate.googleapis.com/translate_a/single';
  var _baseUrl = 'https://translate.google.cn/m';

  TokenProviderInterface tokenProvider;

  /// Translates texts from specified language to another
  Future<String> translate(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    if (sourceText == null || sourceText.length == 0) return "";
    int maxRequestCount = 10;
    int requestCount = 0;
    String returnString;
    do {
      requestCount++;
      returnString =
          await this.translateFromGoogle(sourceText, from: from, to: to);
    } while (returnString == null && requestCount < maxRequestCount);
    return returnString ?? "";
  }

  /// Translates texts from specified language to another
  Future<String> translateFromGoogle(String sourceText,
      {from = 'auto', to = 'en'}) async {
    /// Assertion for supported language
    [from, to].forEach((language) {
      assert(Languages.isSupported(language),
          "\n\/E:\t\tError -> Not a supported language: '$language'");
    });

    /// New tokenProvider -> uses GoogleTokenGenerator for free API
    // tokenProvider = GoogleTokenGenerator();
    try {
      var parameters = {
        'client': 't',
        'sl': from,
        'tl': to,
        'dt': 't',
        'ie': 'UTF-8',
        'oe': 'UTF-8',
        // 'tk': tokenProvider.generateToken(sourceText),
        'q': sourceText
      };

      /// Append parameters in url
      var str = '';
      parameters.forEach((key, value) {
        if (key == 'q') {
          str += (key + '=' + Uri.encodeComponent(value));
          return;
        }
        str += (key + '=' + Uri.encodeComponent(value) + '&');
      });

      var url = _baseUrl + '?' + str;

      /// Fetch and parse data from Google Transl. API
      final data = await http.get(url);
      if (data.statusCode != 200) {
        print(data.statusCode);
        return null;
      }

      // final jsonData = jsonDecode(data.body);

      // final sb = StringBuffer();
      // for (var c = 0; c < jsonData[0].length; c++) {
      //   sb.write(jsonData[0][c][0]);
      // }

      Document document = parse(data.body);
      // <div dir="ltr" class="t0">你好吗</div>
      var result = document.querySelector('[class="t0"]').text;

      return result;
    } on Error catch (err) {
      print('Error: $err\n${err.stackTrace}');
      return null;
    }
  }

  /// Translates and prints directly
  void translateAndPrint(String text,
      {String from = 'auto', String to = 'en'}) {
    translate(text, from: from, to: to).then((s) {
      print(s);
    });
  }

  /// Sets base URL for countries that default url doesn't work
  void set baseUrl(var base) => _baseUrl = base;
}
