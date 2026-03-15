import React from "react"
import AppLayout from "../layouts/AppLayout"

export default function Home() {
  return (
    <AppLayout>
      <div className="home">
        <h1>Newsprint</h1>
        <p>Turn your favourite email newsletters into a beautiful printed newspaper.</p>
        <a href="/auth/google_oauth2" className="btn-primary">
          Connect Gmail
        </a>
      </div>
    </AppLayout>
  )
}
