'use client'

import { Database } from '@/lib/database.types'
import { useState } from 'react'

type Note = Database['public']['Tables']['notes']['Row']

interface NoteCardProps {
  note: Note
  onUpdate: (id: string, title: string, content: string) => Promise<void>
  onDelete: (id: string) => Promise<void>
}

export default function NoteCard({ note, onUpdate, onDelete }: NoteCardProps) {
  const [isEditing, setIsEditing] = useState(false)
  const [title, setTitle] = useState(note.title)
  const [content, setContent] = useState(note.content)
  const [isDeleting, setIsDeleting] = useState(false)

  const handleSave = async () => {
    await onUpdate(note.id, title, content)
    setIsEditing(false)
  }

  const handleDelete = async () => {
    if (confirm('Are you sure you want to delete this note?')) {
      setIsDeleting(true)
      await onDelete(note.id)
    }
  }

  if (isDeleting) {
    return (
      <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm opacity-50">
        <p className="text-gray-500">Deleting...</p>
      </div>
    )
  }

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm transition hover:shadow-md">
      {isEditing ? (
        <div className="space-y-4">
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full rounded border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            placeholder="Note title"
          />
          <textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            className="w-full rounded border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            rows={6}
            placeholder="Note content"
          />
          <div className="flex gap-2">
            <button
              onClick={handleSave}
              className="rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
            >
              Save
            </button>
            <button
              onClick={() => {
                setIsEditing(false)
                setTitle(note.title)
                setContent(note.content)
              }}
              className="rounded bg-gray-200 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-300"
            >
              Cancel
            </button>
          </div>
        </div>
      ) : (
        <div>
          <div className="mb-4 flex items-start justify-between">
            <h3 className="text-lg font-semibold text-gray-900">{note.title}</h3>
            <div className="flex gap-2">
              <button
                onClick={() => setIsEditing(true)}
                className="text-sm text-blue-600 hover:text-blue-800"
              >
                Edit
              </button>
              <button
                onClick={handleDelete}
                className="text-sm text-red-600 hover:text-red-800"
              >
                Delete
              </button>
            </div>
          </div>
          <p className="text-gray-700 whitespace-pre-wrap">{note.content}</p>
          <div className="mt-4 flex items-center gap-4 text-xs text-gray-500">
            <span>Created: {new Date(note.created_at).toLocaleDateString()}</span>
            {note.updated_at !== note.created_at && (
              <span>Updated: {new Date(note.updated_at).toLocaleDateString()}</span>
            )}
            {note.is_public && (
              <span className="rounded bg-green-100 px-2 py-1 text-green-800">Public</span>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
