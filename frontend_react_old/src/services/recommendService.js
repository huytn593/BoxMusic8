const API_BASE = `${process.env.REACT_APP_API_BASE_URL}`;

export async function getRecommendTrack(userId, handleSessionOut) {
    const res = await fetch(`${API_BASE}/api/Track/recommend-track/${userId}`, {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
    });

    if (res.status === 200) {
        return res.json();
    } else if (res.status === 401 || res.status === 403) {
        handleSessionOut();
    } else {
        return { success: false, status: res.status };
    }
}
