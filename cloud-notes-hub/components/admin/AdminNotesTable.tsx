'use client'

import { Database } from '@/lib/database.types'
import { useState } from 'react'

type Note = Database['public']['Tables']['notes']['Row']
type Profile = Database['public']['Tables']['profiles']['Row']

interface AdminNotesTableProps {
  notes: Note[]
  profiles: Profile[]
  onDelete: (id: string) => Promise<void>
  onUpdate: (id: string, updates: Partial<Note>) => Promise<void>
}

export default function AdminNotesTable({
  notes,
  profiles,
  onDelete,
  onUpdate,
}: AdminNotesTableProps) {
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editTitle, setEditTitle] = useState('')
  const [editContent, setEditContent] = useState('')

  const getUserEmail = (userId: string) => {
    const profile = profiles.find((p) => p.id === userId)
    return profile?.email || 'Unknown'
  }

  const handleEdit = (note: Note) => {
    setEditingId(note.id)
    setEditTitle(note.title)
    setEditContent(note.content)
  }

  const handleSave = async (id: string) => {
    await onUpdate(id, {
      title: editTitle,
      content: editContent,
    })
    setEditingId(null)
  }

  const handleCancel = () => {
    setEditingId(null)
    setEditTitle('')
    setEditContent('')
  }

  const togglePublic = async (note: Note) => {
    await onUpdate(note.id, {
      is_public: !note.is_public,
    })
  }

  return (
    <div className="overflow-hidden rounded-lg border border-gray-200 bg-white shadow">
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Title
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Content Preview
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Author
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Status
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Created
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {notes.map((note) => (
              <tr key={note.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  {editingId === note.id ? (
                    <input
                      type="text"
                      value={editTitle}
                      onChange={(e) => setEditTitle(e.target.value)}
                      className="w-full rounded border border-gray-300 px-2 py-1 text-sm focus:border-blue-500 focus:outline-none"
                    />
                  ) : (
                    <div className="text-sm font-medium text-gray-900">
                      {note.title}
                    </div>
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingId === note.id ? (
                    <textarea
                      value={editContent}
                      onChange={(e) => setEditContent(e.target.value)}
                      className="w-full rounded border border-gray-300 px-2 py-1 text-sm focus:border-blue-500 focus:outline-none"
                      rows={2}
                    />
                  ) : (
                    <div className="max-w-xs truncate text-sm text-gray-700">
                      {note.content}
                    </div>
                  )}
                </td>
                <td className="px-6 py-4 text-sm text-gray-700">
                  {getUserEmail(note.user_id)}
                </td>
                <td className="px-6 py-4">
                  <button
                    onClick={() => togglePublic(note)}
                    className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${
                      note.is_public
                        ? 'bg-green-100 text-green-800 hover:bg-green-200'
                        : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
                    }`}
                  >
                    {note.is_public ? 'Public' : 'Private'}
                  </button>
                </td>
                <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-700">
                  {new Date(note.created_at).toLocaleDateString()}
                </td>
                <td className="whitespace-nowrap px-6 py-4 text-sm">
                  {editingId === note.id ? (
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleSave(note.id)}
                        className="text-green-600 hover:text-green-900"
                      >
                        Save
                      </button>
                      <button
                        onClick={handleCancel}
                        className="text-gray-600 hover:text-gray-900"
                      >
                        Cancel
                      </button>
                    </div>
                  ) : (
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleEdit(note)}
                        className="text-blue-600 hover:text-blue-900"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => onDelete(note.id)}
                        className="text-red-600 hover:text-red-900"
                      >
                        Delete
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {notes.length === 0 && (
        <div className="py-12 text-center text-gray-500">No notes found</div>
      )}
    </div>
  )
}
