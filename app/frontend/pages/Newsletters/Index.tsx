import React, { useState } from "react"
import { router } from "@inertiajs/react"
import AppLayout from "../../layouts/AppLayout"
import { Newsletter } from "../../types"

interface Props {
  newsletters: Newsletter[]
  maxPages: number
}

export default function Index({ newsletters, maxPages }: Props) {
  const [selectedIds, setSelectedIds] = useState<Set<number>>(new Set())

  const totalPages = newsletters
    .filter((n) => selectedIds.has(n.id))
    .reduce((sum, n) => sum + n.est_pages, 0)

  const overLimit = totalPages > maxPages
  const canGenerate = selectedIds.size > 0 && !overLimit

  const toggle = (id: number) => {
    setSelectedIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) {
        next.delete(id)
      } else {
        next.add(id)
      }
      return next
    })
  }

  const handleGenerate = () => {
    router.post("/newspapers", {
      newsletter_ids: Array.from(selectedIds),
    })
  }

  return (
    <AppLayout>
      <div className="newsletters">
        <h1>Your Newsletters</h1>
        {newsletters.length === 0 ? (
          <p>No newsletters found. Try scanning your inbox.</p>
        ) : (
          <>
            <ul className="newsletter-list">
              {newsletters.map((newsletter) => {
                const isSelected = selectedIds.has(newsletter.id)
                const isOverLimit = overLimit && isSelected
                return (
                  <li
                    key={newsletter.id}
                    className={`newsletter-item ${isSelected ? "selected" : ""} ${isOverLimit ? "over-limit" : ""}`}
                    data-testid={`newsletter-${newsletter.id}`}
                  >
                    <label className="newsletter-toggle">
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => toggle(newsletter.id)}
                        aria-label={`Select ${newsletter.title}`}
                      />
                      <div className="newsletter-info">
                        <h3>{newsletter.title}</h3>
                        <p className="sender-email">{newsletter.sender_email}</p>
                        <p className="est-pages">{newsletter.est_pages} pages</p>
                        {newsletter.latest_issue_date && (
                          <p className="latest-date">
                            Latest: {new Date(newsletter.latest_issue_date).toLocaleDateString()}
                          </p>
                        )}
                      </div>
                    </label>
                  </li>
                )
              })}
            </ul>

            <div className="selector-footer" data-testid="selector-footer">
              <div className="page-counter" data-testid="page-counter">
                {totalPages} / {maxPages} pages selected
              </div>
              <div className="progress-bar">
                <div
                  className="progress-fill"
                  style={{
                    width: `${Math.min((totalPages / maxPages) * 100, 100)}%`,
                    backgroundColor: overLimit ? "#e53e3e" : "#38a169",
                  }}
                />
              </div>
              {overLimit && (
                <p className="warning" data-testid="warning">
                  Page limit exceeded — deselect a newsletter
                </p>
              )}
              <button
                className="btn-primary generate-btn"
                disabled={!canGenerate}
                onClick={handleGenerate}
                data-testid="generate-btn"
              >
                Generate Newspaper
              </button>
            </div>
          </>
        )}
      </div>
    </AppLayout>
  )
}
