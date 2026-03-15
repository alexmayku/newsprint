import React, { useEffect, useState } from "react"
import { router } from "@inertiajs/react"
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
}

export default function Preview({ newspaper }: Props) {
  const [status, setStatus] = useState(newspaper.status)
  const [pdfUrl, setPdfUrl] = useState(newspaper.pdf_url)

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
        }
      } catch {
        clearInterval(interval)
      }
    }, 2000)

    return () => clearInterval(interval)
  }, [newspaper.id, status])

  return (
    <AppLayout>
      <div className="newspaper-preview">
        <h1>{newspaper.title}</h1>
        <p>Edition {newspaper.edition_number}</p>

        <div className="status">
          {status === "generated" ? (
            <>
              <p>Your newspaper is ready!</p>
              {newspaper.pdf_url && (
                <a href={newspaper.pdf_url} className="btn-primary" target="_blank" rel="noopener">
                  Download PDF
                </a>
              )}
              {newspaper.page_count && <p>{newspaper.page_count} pages</p>}
            </>
          ) : status === "failed" ? (
            <p className="error">Generation failed. Please try again.</p>
          ) : (
            <>
              <div className="spinner" aria-label="Loading">
                <div className="spinner-animation" />
              </div>
              <p>Generating your newspaper...</p>
              <p className="status-detail">{status}</p>
            </>
          )}
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
