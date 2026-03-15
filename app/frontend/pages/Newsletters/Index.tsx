import React from "react"
import AppLayout from "../../layouts/AppLayout"
import { Newsletter } from "../../types"

interface Props {
  newsletters: Newsletter[]
}

export default function Index({ newsletters }: Props) {
  return (
    <AppLayout>
      <div className="newsletters">
        <h1>Your Newsletters</h1>
        {newsletters.length === 0 ? (
          <p>No newsletters found. Try scanning your inbox.</p>
        ) : (
          <ul className="newsletter-list">
            {newsletters.map((newsletter) => (
              <li key={newsletter.id} className="newsletter-item">
                <h3>{newsletter.title}</h3>
                <p className="sender-email">{newsletter.sender_email}</p>
                <p className="est-pages">{newsletter.est_pages} pages</p>
              </li>
            ))}
          </ul>
        )}
      </div>
    </AppLayout>
  )
}
