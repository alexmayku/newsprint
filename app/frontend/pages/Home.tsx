import React from "react"
import AppLayout from "../layouts/AppLayout"

export default function Home() {
  return (
    <AppLayout>
      <div className="home">
        <h1>Newsprint</h1>
        <p>Turn your favourite email newsletters into a beautiful printed newspaper.</p>
        <form action="/auth/google_oauth2" method="post">
          <input type="hidden" name="authenticity_token" value={
            document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
          } />
          <button type="submit" className="btn-primary">
            Connect Gmail
          </button>
        </form>
      </div>
    </AppLayout>
  )
}
