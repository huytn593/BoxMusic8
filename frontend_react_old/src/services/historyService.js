const API_BASE = `${process.env.REACT_APP_API_BASE_URL}`;

const BASE_URL = `${API_BASE}/api/History`;

export const getUserHistory = async (userId) => {
    try {
        const response = await fetch(`${BASE_URL}/user/${userId}`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });
        if (!response.ok) throw new Error('Failed to fetch history');
        return await response.json();
    } catch (error) {
        console.error('Error fetching user history:', error);
        throw error;
    }
};

export const deleteHistoryTrack = async (trackId) => {
    try {
        const response = await fetch(`${BASE_URL}/delete/${trackId}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });
        if (!response.ok) throw new Error('Failed to delete history track');
        return true;
    } catch (error) {
        console.error('Error deleting history track:', error);
        throw error;
    }
};

export const deleteAllHistory = async () => {
    try {
        const response = await fetch(`${BASE_URL}/delete-all`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });
        if (!response.ok) throw new Error('Failed to delete all history');
        return true;
    } catch (error) {
        console.error('Error deleting all history:', error);
        throw error;
    }
};
