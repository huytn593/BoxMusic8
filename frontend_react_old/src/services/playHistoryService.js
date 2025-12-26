const API_BASE = `${process.env.REACT_APP_API_BASE_URL}`;

export const updateHistory = async (trackId) => {
    const res = await fetch(`${API_BASE}/api/History/play/${trackId}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
        }
    });

    if (res.status === 401 || res.status === 403) {
        return false;
    }
};
