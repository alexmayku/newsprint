import React, { useEffect, useState } from "react"
import { router } from "@inertiajs/react"
import AppLayout from "../../layouts/AppLayout"

interface Props {
  jobId: string
}

const STATUS_MESSAGES: Record<string, string> = {
  pending: "Starting scan...",
  scanning: "Scanning your inbox...",
  detecting: "Detecting newsletters...",
}

export default function Discovering({ jobId }: Props) {
  const [status, setStatus] = useState("pending")
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const interval = setInterval(async () => {
      try {
        const response = await fetch(`/newsletters/discover/${jobId}/status`)
        const data = await response.json()
        const currentStatus = data.status as string

        setStatus(currentStatus)

        if (currentStatus.startsWith("complete")) {
          clearInterval(interval)
          router.visit("/newsletters")
        } else if (currentStatus.startsWith("failed")) {
          clearInterval(interval)
          const message = currentStatus.replace("failed:", "")
          setError(message || "Something went wrong")
        }
      } catch {
        clearInterval(interval)
        setError("Failed to check status")
      }
    }, 2000)

    return () => clearInterval(interval)
  }, [jobId])

  const handleRetry = () => {
    setError(null)
    setStatus("pending")
    router.post("/newsletters/discover")
  }

  const displayMessage = error
    ? error
    : STATUS_MESSAGES[status] || "Almost done..."

  return (
    <AppLayout>
      <div className="discovering">
        {!error && (
          <div className="spinner" aria-label="Loading">
            <div className="spinner-animation" />
          </div>
        )}
        <h2>{error ? "Scan Failed" : "Discovering Newsletters"}</h2>
        <p className="status-message">{displayMessage}</p>
        {error && (
          <button onClick={handleRetry} className="btn-primary">
            Try Again
          </button>
        )}
      </div>
    </AppLayout>
  )
}
