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
    <div className="min-h-screen bg-background text-foreground">
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
  )
}

export default App
