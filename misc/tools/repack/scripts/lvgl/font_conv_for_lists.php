<?php
$fontDir = __DIR__ . '/../../src/fonts/';
if (isset($_POST['font'])) {
    $_POST['font'] = $fontDir . basename($_POST['font']);
}
$configs = require __DIR__ . '/font_configs.php';

  echo "Character Convert: Unicode, Decimal NCRs, Url Encoded\n";

  /*
   * Configs
   */
  // https://fontawesome.com/v4.7.0/icons/
  // label: unicode
  $unicodes = array(
    "THERMOMETER_EMPTY" => "f2cb",
    "TINT             " => "f043",
    "BALANCE_SCALE    " => "f24e",
    "BARS             " => "f0c9",
    "MICROCHIP        " => "f2db"
  );

  // a. Parameters
  $decimal_ncrs = "";

  foreach ($unicodes as $label => $unicode) {
    $utf8 = unicode_to_utf8($unicode);
    $decimal = unicode_to_decimal_ncrs($unicode);
    $encoded = urlencode($decimal);

    $decimal_ncrs = $decimal_ncrs . $decimal;

    //echo "\n";
    //echo "Unicode: $unicode\n";
    //echo "Decimal NCRs: $decimal_ncrs\n";
    //echo "Url Encoded: $encoded\n";
    //echo "UTF-8: $utf8";
    //echo "\n";
  }
  //echo "\n";

  // b. Convert
  $output_dir = __DIR__ . "/../../build/fonts/";

  foreach ($configs as $cfg) {

      $name      = $cfg["name"];
      $font      = $cfg["font"];
      $height    = $cfg["height"];
      $bpp       = $cfg["bpp"];
      $uni_first = $cfg["uni_first"];
      $uni_last  = $cfg["uni_last"];
      $encodeds  = urlencode($cfg["chars"]);

      $name_with_c = "$name.c";

      $cmd = "php " . __DIR__ . "/font_conv_core.php "
           . "\"name=$name&font=$font&height=$height&bpp=$bpp"
           . "&uni_first=$uni_first&uni_last=$uni_last"
           . "&built_in_sym=0&list=$encodeds\"";

      //echo "Running: $cmd\n";
      shell_exec($cmd);

      shell_exec("mkdir -p $output_dir");
      //shell_exec("mv " . __DIR__ . "/$name_with_c $output_dir/$name_with_c");
  }

  // c. Move
  //shell_exec("mkdir $output_dir");
  //shell_exec("mv " . __DIR__ . "/$name_with_c $output_dir/$name_with_c");

  // d. Usage
  //usage($name, $unicodes, $height);

  function usage($name, $unicodes, $height)
  {
    echo "\nUSAGE\n\n";

    // a. define
    $labels = "";
    echo "a. Define\n";
    foreach ($unicodes as $label => $unicode) {
      $utf8 = unicode_to_utf8($unicode);

      $str = <<<HERO
#define LV_SYMBOL_$label \t"$utf8"\n
HERO;

      echo $str;

      $labels = $labels . "LV_SYMBOL_$label ";
    }

    echo "\n";

    // b. add font
    echo "b. Add font\n";
    $lvgl_font = "lv_font_symbol_$height";
    echo "lv_font_add(&$name, &$lvgl_font);\n";

    // c. Style
    $str = <<<HERO
static lv_style_t style;
lv_style_copy(&style, &lv_style_plain);
style.text.font = &$lvgl_font;
HERO;
    echo "$str\n";

    // c. Declare
    echo "\nc. Declare\n";
    echo "LV_FONT_DECLARE($name)\n";

    // d. Use it;)
    echo "\nd. Use it;)\n";
    $str = <<<HERO
lv_obj_t * label = lv_label_create(scr, NULL);
lv_label_set_style(label, &style);
lv_label_set_text(label, $labels);
HERO;
    echo "$str\n";
  }

  // Usage: unicode_to_utf8("f2cb");
  function unicode_to_utf8($unicode)
  {
    $tmp = json_decode('"\u' . $unicode . '"');
    $n = strlen($tmp);
    $str = "";

    for ($i = 0; $i < $n; $i++) {
      $d = ord($tmp[$i]);

      $h = dechex($d);

      $str = $str . "\x" . $h;
    }

    return $str;
  }

  // Usage: unicode_to_decimal_ncrs("f2cb");
  function unicode_to_decimal_ncrs($unicode)
  {
    $dec = "&#" . hexdec($unicode) . ";";

    return $dec;
  }
exit;
?>