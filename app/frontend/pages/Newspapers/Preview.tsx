import React, { useEffect, useState } from "react"
import { router, Link } from "@inertiajs/react"
import AppLayout from "../../layouts/AppLayout"

interface NewspaperProps {
  id: number
  title: string
  edition_number: number
  page_count: number | null
  status: string
  pdf_url: string | null
  generated_at: string | null
  newsletters: { id: number; title: string; sender_email: string }[]
}

interface Props {
  newspaper: NewspaperProps
  jobId?: string | null
}

const STATUS_MESSAGES: Record<string, string> = {
  draft: "Preparing your newspaper...",
  generating: "Generating your newspaper...",
  extracting: "Extracting newsletter content...",
  rendering: "Rendering pages...",
  processing: "Processing PDF...",
}

export default function Preview({ newspaper, jobId }: Props) {
  const [status, setStatus] = useState(newspaper.status)
  const [viewMode, setViewMode] = useState<"single" | "spread">("single")

  useEffect(() => {
    if (status === "generated" || status === "failed") return

    const interval = setInterval(async () => {
      try {
        const response = await fetch(`/newspapers/${newspaper.id}/status`)
        const data = await response.json()
        const currentStatus = data.status as string

        setStatus(currentStatus)

        if (currentStatus.startsWith("complete") || currentStatus === "generated") {
          clearInterval(interval)
          router.reload()
        } else if (currentStatus.startsWith("failed") || currentStatus === "failed") {
          clearInterval(interval)
          setStatus("failed")
        }
      } catch {
        clearInterval(interval)
      }
    }, 2000)

    return () => clearInterval(interval)
  }, [newspaper.id, status])

  const handleRetry = () => {
    const newsletterIds = newspaper.newsletters.map((n) => n.id)
    router.post("/newspapers", { newsletter_ids: newsletterIds })
  }

  if (status === "failed") {
    return (
      <AppLayout>
        <div className="newspaper-preview">
          <h1>{newspaper.title}</h1>
          <p>Edition {newspaper.edition_number}</p>
          <div className="error-state">
            <p className="error">Generation failed. Something went wrong while creating your newspaper.</p>
            <button onClick={handleRetry} className="btn-primary" data-testid="retry-btn">
              Try Again
            </button>
            <Link href="/newsletters" className="btn-secondary" data-testid="back-btn">
              Back to Selector
            </Link>
          </div>
        </div>
      </AppLayout>
    )
  }

  if (status !== "generated") {
    return (
      <AppLayout>
        <div className="newspaper-preview">
          <h1>{newspaper.title}</h1>
          <p>Edition {newspaper.edition_number}</p>
          <div className="loading-state">
            <div className="spinner" aria-label="Loading">
              <div className="spinner-animation" />
            </div>
            <p>{STATUS_MESSAGES[status] || "Working on it..."}</p>
            <p className="status-detail">{status}</p>
          </div>
        </div>
      </AppLayout>
    )
  }

  return (
    <AppLayout>
      <div className="newspaper-preview">
        <div className="preview-header">
          <h1>{newspaper.title}</h1>
          <p>Edition {newspaper.edition_number}</p>
          {newspaper.page_count && <p data-testid="page-count">{newspaper.page_count} pages</p>}
          {newspaper.generated_at && (
            <p className="generated-date">
              Generated {new Date(newspaper.generated_at).toLocaleDateString()}
            </p>
          )}
        </div>

        <div className="preview-actions">
          <div className="view-toggle">
            <button
              className={viewMode === "single" ? "active" : ""}
              onClick={() => setViewMode("single")}
            >
              Single Page
            </button>
            <button
              className={viewMode === "spread" ? "active" : ""}
              onClick={() => setViewMode("spread")}
            >
              Spread View
            </button>
          </div>
        </div>

        {newspaper.pdf_url && (
          <div className={`pdf-viewer ${viewMode}`}>
            <iframe
              src={newspaper.pdf_url}
              title="Newspaper Preview"
              className="pdf-iframe"
            />
          </div>
        )}

        <div className="preview-footer">
          <Link href="/newsletters" className="btn-secondary" data-testid="back-btn">
            Back to Selector
          </Link>
          <Link
            href={`/orders/new?newspaper_id=${newspaper.id}`}
            className="btn-primary"
            data-testid="purchase-btn"
          >
            Purchase
          </Link>
        </div>

        <div className="included-newsletters">
          <h3>Included Newsletters</h3>
          <ul>
            {newspaper.newsletters.map((n) => (
              <li key={n.id}>{n.title}</li>
            ))}
          </ul>
        </div>
      </div>
    </AppLayout>
  )
}
