export function csrfHeaders(headers = {}) {
  const token = document.querySelector('meta[name="csrf-token"]')?.content

  return token ? { ...headers, "X-CSRF-Token": token } : headers
}

export function apiFetch(url, options = {}) {
  return fetch(url, {
    ...options,
    headers: csrfHeaders({ Accept: "application/json", ...(options.headers || {}) }),
  })
}