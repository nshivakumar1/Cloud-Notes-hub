'use client'

import { createClient } from '@/lib/supabase/client'
import { Database } from '@/lib/database.types'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import AdminNotesTable from '@/components/admin/AdminNotesTable'

type Note = Database['public']['Tables']['notes']['Row']
type Profile = Database['public']['Tables']['profiles']['Row']

export default function AdminPage() {
  const [notes, setNotes] = useState<Note[]>([])
  const [profiles, setProfiles] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('')
  const [publicFilter, setPublicFilter] = useState<'all' | 'public' | 'private'>('all')
  const supabase = createClient()
  const router = useRouter()

  useEffect(() => {
    const checkAuth = async () => {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) {
        router.push('/login')
        return
      }

      // Check if user is admin
      const { data: profileData } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', session.user.id)
        .single()

      if (!profileData?.is_admin) {
        router.push('/dashboard')
        return
      }

      // Fetch all data
      await fetchData()
      setLoading(false)
    }

    checkAuth()

    // Subscribe to realtime changes
    const notesChannel = supabase
      .channel('admin-notes-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'notes',
        },
        () => {
          fetchData()
        }
      )
      .subscribe()

    const profilesChannel = supabase
      .channel('admin-profiles-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'profiles',
        },
        () => {
          fetchProfiles()
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(notesChannel)
      supabase.removeChannel(profilesChannel)
    }
  }, [supabase, router])

  const fetchData = async () => {
    await Promise.all([fetchNotes(), fetchProfiles()])
  }

  const fetchNotes = async () => {
    const { data } = await supabase
      .from('notes')
      .select('*')
      .order('created_at', { ascending: false })

    if (data) {
      setNotes(data)
    }
  }

  const fetchProfiles = async () => {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })

    if (data) {
      setProfiles(data)
    }
  }

  const deleteNote = async (id: string) => {
    if (!confirm('Are you sure you want to delete this note?')) return

    const { error } = await supabase
      .from('notes')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Error deleting note:', error)
      alert('Error deleting note')
    } else {
      await fetchNotes()
    }
  }

  const updateNote = async (id: string, updates: Partial<Note>) => {
    const { error } = await supabase
      .from('notes')
      .update(updates)
      .eq('id', id)

    if (error) {
      console.error('Error updating note:', error)
      alert('Error updating note')
    } else {
      await fetchNotes()
    }
  }

  const filteredNotes = notes.filter((note) => {
    const matchesSearch =
      note.title.toLowerCase().includes(filter.toLowerCase()) ||
      note.content.toLowerCase().includes(filter.toLowerCase())

    const matchesPublicFilter =
      publicFilter === 'all' ||
      (publicFilter === 'public' && note.is_public) ||
      (publicFilter === 'private' && !note.is_public)

    return matchesSearch && matchesPublicFilter
  })

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="text-lg">Loading...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="border-b border-gray-200 bg-white">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 items-center justify-between">
            <h1 className="text-xl font-bold text-gray-900">Admin Dashboard</h1>
            <div className="flex items-center gap-4">
              <button
                onClick={() => router.push('/dashboard')}
                className="text-sm text-blue-600 hover:text-blue-800"
              >
                Back to Dashboard
              </button>
              <button
                onClick={async () => {
                  await supabase.auth.signOut()
                  router.push('/login')
                }}
                className="rounded bg-gray-200 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-300"
              >
                Sign Out
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
        <div className="mb-8">
          <h2 className="mb-4 text-2xl font-bold text-gray-900">All Notes</h2>

          <div className="mb-4 flex gap-4">
            <input
              type="text"
              value={filter}
              onChange={(e) => setFilter(e.target.value)}
              placeholder="Search notes..."
              className="flex-1 rounded border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
            <select
              value={publicFilter}
              onChange={(e) => setPublicFilter(e.target.value as 'all' | 'public' | 'private')}
              className="rounded border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="all">All Notes</option>
              <option value="public">Public Only</option>
              <option value="private">Private Only</option>
            </select>
          </div>

          <div className="mb-4 text-sm text-gray-600">
            Total Notes: {filteredNotes.length} | Total Users: {profiles.length}
          </div>
        </div>

        <AdminNotesTable
          notes={filteredNotes}
          profiles={profiles}
          onDelete={deleteNote}
          onUpdate={updateNote}
        />
      </main>
    </div>
  )
}
