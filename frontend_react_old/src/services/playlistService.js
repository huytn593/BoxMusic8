const API_BASE = `${process.env.REACT_APP_API_BASE_URL}`;

export const getUserPlaylists = async (userId) => {
    try {
        const response = await fetch(`${API_BASE}/api/Playlist/user/${userId}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`,
            },
        });

        if (!response.ok) {
            throw new Error('Failed to fetch playlists');
        }

        return await response.json();
    } catch (error) {
        throw error;
    }
};

export const getPlaylistDetail = async (playlistId) => {
    try {
        const response = await fetch(`${API_BASE}/api/Playlist/${playlistId}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`,
            },
        });

        if (!response.ok) {
            throw new Error('Failed to fetch playlist detail');
        }

        return await response.json();
    } catch (error) {
        throw error;
    }
};

export const createPlaylist = async (playlistData) => {
    try {
        const response = await fetch(`${API_BASE}/api/Playlist`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`,
            },
            body: JSON.stringify(playlistData),
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'Failed to create playlist');
        }

        return await response.json();
    } catch (error) {
        throw error;
    }
};

export const updatePlaylist = async (playlistId, playlistData) => {
    try {
        const response = await fetch(`${API_BASE}/api/Playlist/${playlistId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`,
            },
            body: JSON.stringify(playlistData),
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'Failed to update playlist');
        }

        return await response.json();
    } catch (error) {
        throw error;
    }
};

export const deletePlaylist = async (playlistId) => {
    try {
        const response = await fetch(`${API_BASE}/api/Playlist/${playlistId}`, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`,
            },
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'Failed to delete playlist');
        }

        return await response.json();
    } catch (error) {
        throw error;
    }
};

export const addTrackToPlaylist = async (playlistId, trackId) => {
    try {
        const response = await fetch(`${API_BASE}/api/Playlist/${playlistId}/tracks`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`,
            },
            body: JSON.stringify({ trackId }),
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'Failed to add track to playlist');
        }

        return await response.json();
    } catch (error) {
        throw error;
    }
};

export const removeTrackFromPlaylist = async (playlistId, trackId) => {
    try {
        const response = await fetch(`${API_BASE}/api/Playlist/${playlistId}/tracks/${trackId}`, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`,
            },
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'Failed to remove track from playlist');
        }

        return await response.json();
    } catch (error) {
        throw error;
    }
};

export const getUserPlaylistLimits = async (userId) => {
    try {
        const response = await fetch(`${API_BASE}/api/Playlist/limits/${userId}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`,
            },
        });

        if (!response.ok) {
            throw new Error('Failed to fetch playlist limits');
        }

        return await response.json();
    } catch (error) {
        throw error;
    }
};
