export interface Newsletter {
  id: number
  title: string
  sender_email: string
  est_pages: number
  latest_issue_date: string
  logo_url: string | null
}

export interface NewspaperDetail {
  id: number
  title: string
  edition_number: number
  page_count: number | null
  status: string
  pdf_url: string | null
  generated_at: string | null
}

export interface OrderDetail {
  id: number
  order_number: string
  order_type: string
  frequency: string | null
  status: string
  page_count: number
  delivery_address: object
  created_at: string
}
