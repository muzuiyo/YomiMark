import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { Copy, Check } from "lucide-react"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

const API_URL = import.meta.env.VITE_API_URL || "http://127.0.0.1:8787"

const MODES = [
  { value: "furigana", label: "振假名" },
  { value: "okurigana", label: "送假名" },
  { value: "romaji", label: "罗马字" },
] as const

const MODE_ITEMS = Object.fromEntries(MODES.map((m) => [m.value, m.label]))

type Mode = (typeof MODES)[number]["value"]

function App() {
  const [text, setText] = useState("")
  const [mode, setMode] = useState<Mode>("furigana")
  const [result, setResult] = useState("")
  const [resultMode, setResultMode] = useState<Mode>("furigana")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    await navigator.clipboard.writeText(result)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const handleConvert = async () => {
    if (!text.trim()) return

    setLoading(true)
    setError("")
    setResult("")

    try {
      const resp = await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text, mode }),
      })

      const data = await resp.json()

      if (!resp.ok) {
        setError(data.error || "Request failed")
        return
      }

      setResult(data.result)
      setResultMode(mode)
    } catch (err) {
      setError(err instanceof Error ? err.message : "Network error")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground">
      <div className="flex-1">
        <div className="mx-auto max-w-3xl px-6 py-12">
          <header className="mb-10 text-center">
            <h1 className="text-3xl font-bold tracking-tight">YomiMark</h1>
            <p className="mt-2 text-muted-foreground">
              日文注音工具 — 输入日文，获取振假名、送假名或罗马字标注
            </p>
          </header>

          <div className="space-y-4">
            <Textarea
              placeholder="ここに日本語のテキストを入力してください..."
              value={text}
              onChange={(e) => setText(e.target.value)}
              className="min-h-40 text-base"
            />

            <div className="flex items-center gap-3">
              <Select items={MODE_ITEMS} value={mode} onValueChange={(v) => setMode(v as Mode)}>
                <SelectTrigger className="w-36">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent side="bottom" sideOffset={8}>
                  {MODES.map((m) => (
                    <SelectItem key={m.value} value={m.value}>
                      {m.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>

              <Button onClick={handleConvert} disabled={loading || !text.trim()}>
                {loading ? "解析中..." : "解析"}
              </Button>
            </div>
          </div>

          {error && (
            <div className="mt-6 rounded-lg border border-destructive/50 bg-destructive/10 px-4 py-3 text-sm text-destructive">
              {error}
            </div>
          )}

          {result && (
            <div className="mt-6">
              <div className="mb-3 flex items-center justify-between">
                <h2 className="text-lg font-semibold text-foreground">
                  解析结果
                </h2>
                <Button variant="ghost" size="sm" onClick={handleCopy}>
                  {copied ? <Check className="size-4" /> : <Copy className="size-4" />}
                  {copied ? "已复制" : "复制"}
                </Button>
              </div>
              <div className="rounded-lg border bg-card p-6 text-lg leading-relaxed whitespace-pre-line text-card-foreground [&_ruby]:text-base [&_rt]:text-xs [&_rt]:text-muted-foreground">
                {resultMode === "furigana" ? (
                  <div dangerouslySetInnerHTML={{ __html: result.replace(/\\N/g, "\n") }} />
                ) : (
                  result.replace(/\\N/g, "\n")
                )}
              </div>
            </div>
          )}
        </div>
      </div>

      <footer className="mx-auto max-w-3xl px-6 py-12">
        <p className="text-sm text-muted-foreground whitespace-nowrap">
          Powered by{" "}
          <a
            href="https://github.com/muzuiyo/YomiMark"
            target="_blank"
            rel="noopener noreferrer"
            className="font-medium hover:underline transition-colors inline"
          >
            yomimark
          </a>
          {" "}|{" "}
          <a
            href="https://github.com/muzuiyo/YomiMark/tree/main/plugin"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 font-medium hover:underline transition-colors"
          >
            Aegisub Plugin
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="inline"
            >
              <path d="M15 3h6v6" />
              <path d="M10 14 21 3" />
              <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
            </svg>
          </a>
        </p>
      </footer>
    </div>
  )
}

export default App
