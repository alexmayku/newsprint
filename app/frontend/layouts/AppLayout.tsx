import React from "react"

interface AppLayoutProps {
  children: React.ReactNode
}

export default function AppLayout({ children }: AppLayoutProps) {
  return (
    <div className="app">
      <header className="app-header">
        <div className="logo">
          <a href="/">Newsprint</a>
        </div>
        <nav></nav>
      </header>

      <main className="app-main">{children}</main>

      <footer className="app-footer">
        <p>&copy; {new Date().getFullYear()} Newsprint</p>
      </footer>
    </div>
  )
}
