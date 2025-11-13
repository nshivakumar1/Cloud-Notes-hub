'use client'

import { createClient } from '@/lib/supabase/client'
import { Database } from '@/lib/database.types'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import NoteCard from '@/components/notes/NoteCard'
import NewNoteForm from '@/components/notes/NewNoteForm'

type Note = Database['public']['Tables']['notes']['Row']
type Profile = Database['public']['Tables']['profiles']['Row']

export default function DashboardPage() {
  const [notes, setNotes] = useState<Note[]>([])
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const supabase = createClient()
  const router = useRouter()

  const fetchNotes = async () => {
    const { data } = await supabase
      .from('notes')
      .select('*')
      .order('created_at', { ascending: false })

    if (data) {
      setNotes(data)
    }
  }

  useEffect(() => {
    const checkAuth = async () => {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) {
        router.push('/login')
        return
      }

      // Fetch user profile
      const { data: profileData } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', session.user.id)
        .single()

      setProfile(profileData)

      // Fetch notes
      await fetchNotes()
      setLoading(false)
    }

    checkAuth()

    // Subscribe to realtime changes
    const channel = supabase
      .channel('notes-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'notes',
        },
        () => {
          fetchNotes()
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [supabase, router, fetchNotes])

  const createNote = async (title: string, content: string, isPublic: boolean) => {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) return

    const { error } = await supabase
      .from('notes')
      .insert({
        title,
        content,
        is_public: isPublic,
        user_id: session.user.id,
      })

    if (error) {
      console.error('Error creating note:', error)
    } else {
      await fetchNotes()
    }
  }

  const updateNote = async (id: string, title: string, content: string) => {
    const { error } = await supabase
      .from('notes')
      .update({ title, content })
      .eq('id', id)

    if (error) {
      console.error('Error updating note:', error)
    } else {
      await fetchNotes()
    }
  }

  const deleteNote = async (id: string) => {
    const { error } = await supabase
      .from('notes')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Error deleting note:', error)
    } else {
      await fetchNotes()
    }
  }

  const handleSignOut = async () => {
    await supabase.auth.signOut()
    router.push('/login')
  }

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
            <h1 className="text-xl font-bold text-gray-900">Cloud Notes Hub 2.0</h1>
            <div className="flex items-center gap-4">
              {profile?.email && (
                <span className="text-sm text-gray-600">{profile.email}</span>
              )}
              {profile?.is_admin && (
                <button
                  onClick={() => router.push('/admin')}
                  className="text-sm text-blue-600 hover:text-blue-800"
                >
                  Admin Dashboard
                </button>
              )}
              <button
                onClick={handleSignOut}
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
          <h2 className="mb-4 text-2xl font-bold text-gray-900">My Notes</h2>
          <NewNoteForm onSubmit={createNote} />
        </div>

        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {notes.map((note) => (
            <NoteCard
              key={note.id}
              note={note}
              onUpdate={updateNote}
              onDelete={deleteNote}
            />
          ))}
        </div>

        {notes.length === 0 && (
          <div className="mt-8 text-center text-gray-500">
            No notes yet. Create your first note to get started!
          </div>
        )}
      </main>
    </div>
  )
}
