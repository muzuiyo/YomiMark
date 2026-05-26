declare module "kuroshiro-analyzer-kuromoji" {
  interface KuromojiAnalyzerOptions {
    dictPath?: string;
  }

  class KuromojiAnalyzer {
    constructor(options?: KuromojiAnalyzerOptions);
    parse(str: string): Promise<unknown>;
  }

  export default KuromojiAnalyzer;
}
