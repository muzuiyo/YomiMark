declare module "kuroshiro" {
  interface KuroshiroOptions {
    mode?: "normal" | "spaced" | "okurigana" | "furigana";
    to?: "hiragana" | "katakana" | "romaji";
    romajiSystem?: "nippon" | "passport" | "hepburn";
    delimiter_start?: string;
    delimiter_end?: string;
  }

  interface Analyzer {
    parse(str: string): Promise<unknown>;
  }

  class Kuroshiro {
    init(analyzer: Analyzer): Promise<void>;
    convert(str: string, options?: KuroshiroOptions): Promise<string>;
  }

  export default Kuroshiro;
}
