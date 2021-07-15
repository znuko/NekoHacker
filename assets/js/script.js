// メニューの開閉
$(".menu-icon, .overlay").on("click", () => {
  $(".menu-icon i, .overlay").toggleClass("hidden");
  $(".menu-list").toggleClass("show");
  $("body").toggleClass("scroll-lock");
});

// 指定したアンカー(#ID)へアニメーションでスクロール
$('a[href^="#"]').click(function (event) {
  //位置・時間調整
  var adjust = 0; // header固定してるときなどに
  var time = 500;
  // 通常のクリックイベントをブロック
  event.preventDefault();
  // クリックした要素のhref属性の値を取得
  var href = $(this).attr("href");
  // リンク先が#か空だったらhtmlに
  var target = $(href == "#" || href == "" ? "html" : href);
  // 表示位置を取得
  var position = target.offset().top + adjust;
  // アニメーションの効果の作成
  $("body,html").animate({ scrollTop: position }, time);
});
