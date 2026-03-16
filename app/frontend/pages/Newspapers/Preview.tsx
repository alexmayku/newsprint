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
  const [currentPage, setCurrentPage] = useState(1)
  const totalPages = newspaper.page_count || 1

  useEffect(() => {
    if (status === "generated" || status === "failed") return

    const interval = setInterval(async () => {
      try {
        const response = await fetch(`/newspapers/${newspaper.id}/status`)
        const data = await response.json()
        const currentStatus = data.status as string

        if (currentStatus === "generated" || currentStatus.startsWith("complete")) {
          clearInterval(interval)
          router.reload()
          return
        } else if (currentStatus === "failed" || currentStatus.startsWith("failed")) {
          clearInterval(interval)
          setStatus("failed")
          return
        }

        setStatus(currentStatus)
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

  const goToPage = (page: number) => {
    if (page >= 1 && page <= totalPages) {
      setCurrentPage(page)
    }
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

  const pdfSrc = newspaper.pdf_url
    ? `${newspaper.pdf_url}#page=${currentPage}`
    : undefined

  return (
    <AppLayout>
      <div className="newspaper-preview">
        <div className="preview-header">
          <div className="preview-title-row">
            <div>
              <h1>{newspaper.title}</h1>
              <p>Edition {newspaper.edition_number}</p>
              {newspaper.page_count && <p data-testid="page-count">{newspaper.page_count} pages</p>}
              {newspaper.generated_at && (
                <p className="generated-date">
                  Generated {new Date(newspaper.generated_at).toLocaleDateString()}
                </p>
              )}
            </div>
            <div className="preview-header-actions">
              {newspaper.pdf_url && (
                <a
                  href={newspaper.pdf_url}
                  className="btn-primary"
                  target="_blank"
                  rel="noopener"
                  data-testid="download-pdf"
                >
                  Download PDF
                </a>
              )}
            </div>
          </div>
        </div>

        {newspaper.pdf_url && (
          <div className="pdf-viewer-container">
            <div className="pdf-navigation">
              <button
                onClick={() => goToPage(currentPage - 1)}
                disabled={currentPage <= 1}
                data-testid="prev-page"
                className="nav-btn"
              >
                Previous
              </button>
              <span data-testid="page-indicator" className="page-indicator">
                {currentPage} / {totalPages}
              </span>
              <button
                onClick={() => goToPage(currentPage + 1)}
                disabled={currentPage >= totalPages}
                data-testid="next-page"
                className="nav-btn"
              >
                Next
              </button>
            </div>

            <div className="pdf-viewer">
              <iframe
                key={currentPage}
                src={pdfSrc}
                title="Newspaper Preview"
                className="pdf-iframe"
                data-testid="pdf-iframe"
              />
            </div>
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

      <style>{`
        .newspaper-preview {
          max-width: 1000px;
          margin: 0 auto;
          padding: 20px;
        }
        .preview-title-row {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 20px;
        }
        .preview-header-actions {
          display: flex;
          gap: 10px;
        }
        .pdf-viewer-container {
          margin: 20px 0;
        }
        .pdf-navigation {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 20px;
          padding: 12px;
          background: #f7f7f7;
          border: 1px solid #ddd;
          border-bottom: none;
          border-radius: 8px 8px 0 0;
        }
        .nav-btn {
          padding: 8px 16px;
          border: 1px solid #ccc;
          background: white;
          border-radius: 4px;
          cursor: pointer;
          font-size: 14px;
        }
        .nav-btn:hover:not(:disabled) {
          background: #eee;
        }
        .nav-btn:disabled {
          opacity: 0.4;
          cursor: not-allowed;
        }
        .page-indicator {
          font-size: 14px;
          font-weight: 600;
          min-width: 80px;
          text-align: center;
        }
        .pdf-viewer {
          border: 1px solid #ddd;
          border-radius: 0 0 8px 8px;
          overflow: hidden;
          background: #525659;
        }
        .pdf-iframe {
          width: 100%;
          height: 75vh;
          border: none;
          display: block;
        }
        .preview-footer {
          display: flex;
          gap: 12px;
          margin: 20px 0;
        }
        .btn-primary {
          padding: 10px 20px;
          background: #1a1a1a;
          color: white;
          text-decoration: none;
          border-radius: 6px;
          border: none;
          cursor: pointer;
          font-size: 14px;
        }
        .btn-secondary {
          padding: 10px 20px;
          background: white;
          color: #1a1a1a;
          text-decoration: none;
          border-radius: 6px;
          border: 1px solid #ccc;
          cursor: pointer;
          font-size: 14px;
        }
        .included-newsletters {
          margin-top: 30px;
          padding-top: 20px;
          border-top: 1px solid #eee;
        }
      `}</style>
    </AppLayout>
  )
}
