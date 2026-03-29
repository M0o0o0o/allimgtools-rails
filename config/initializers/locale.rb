SUPPORTED_LOCALES = {
  en:      { name: "English",           native: "English" },
  es:      { name: "Spanish",           native: "Español" },
  fr:      { name: "French",            native: "Français" },
  de:      { name: "German",            native: "Deutsch" },
  it:      { name: "Italian",           native: "Italiano" },
  pt:      { name: "Portuguese",        native: "Português" },
  ja:      { name: "Japanese",          native: "日本語" },
  ru:      { name: "Russian",           native: "Русский" },
  ko:      { name: "Korean",            native: "한국어" },
  "zh-CN": { name: "Chinese Simplified",  native: "中文 (简体)" },
  "zh-TW": { name: "Chinese Traditional", native: "中文 (繁體)" },
  ar:      { name: "Arabic",            native: "العربية" },
  bg:      { name: "Bulgarian",         native: "Български" },
  ca:      { name: "Catalan",           native: "Català" },
  nl:      { name: "Dutch",             native: "Nederlands" },
  el:      { name: "Greek",             native: "Ελληνικά" },
  hi:      { name: "Hindi",             native: "हिन्दी" },
  id:      { name: "Indonesian",        native: "Bahasa Indonesia" },
  ms:      { name: "Malay",             native: "Bahasa Melayu" },
  pl:      { name: "Polish",            native: "Polski" },
  sv:      { name: "Swedish",           native: "Svenska" },
  th:      { name: "Thai",              native: "ภาษาไทย" },
  tr:      { name: "Turkish",           native: "Türkçe" },
  uk:      { name: "Ukrainian",         native: "Українська" },
  vi:      { name: "Vietnamese",        native: "Tiếng Việt" }
}.freeze

I18n.available_locales = SUPPORTED_LOCALES.keys
I18n.default_locale = :en

PUBLIC_LOCALE_PATTERN = Regexp.new(
  (SUPPORTED_LOCALES.keys - [ I18n.default_locale ]).map { |l| Regexp.escape(l.to_s) }.join("|")
)
