export const CHUNK_SIZE = 5 * 1024 * 1024; // 5MB
export const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

// Uploads files in parallel using chunked upload protocol.
//
// callbacks:
//   onError(file, error)   — called when a file fails to upload
//   onFileSettled(file)    — called after each file, whether success or error
export async function uploadFiles(files, taskId, callbacks = {}) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

  await Promise.allSettled(
    files.map(async (file) => {
      try {
        await uploadFile(file, taskId, csrfToken);
      } catch (e) {
        callbacks.onError?.(file, e);
      } finally {
        callbacks.onFileSettled?.(file);
      }
    })
  );
}

async function uploadFile(file, taskId, csrfToken) {
  const uploadId = crypto.randomUUID();
  const totalChunks = Math.ceil(file.size / CHUNK_SIZE);

  for (let i = 0; i < totalChunks; i++) {
    const start = i * CHUNK_SIZE;
    const end = Math.min(start + CHUNK_SIZE, file.size);

    const formData = new FormData();
    formData.append("upload_id", uploadId);
    formData.append("task_id", taskId);
    formData.append("chunk_index", i);
    formData.append("total_chunks", totalChunks);
    formData.append("filename", file.name);
    formData.append("chunk", file.slice(start, end));

    const response = await fetch("/uploads/chunk", {
      method: "POST",
      headers: { "X-CSRF-Token": csrfToken },
      body: formData,
    });

    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Upload failed.");
  }
}
