import React, { useEffect, useState } from 'react';
import { Dropdown, Badge } from 'react-bootstrap';
import { BellFill } from 'react-bootstrap-icons';
import {
    getNotificationsByUserId,
    markNotificationAsViewed
} from '../services/notificationService';
import { useAuth } from '../context/authContext';
import '../styles/NotificationBell.css'

const NotificationBell = () => {
    const { user } = useAuth();
    const [notifications, setNotifications] = useState([]);
    const [unreadCount, setUnreadCount] = useState(0);

    const formatTimeAgo = (isoTime) => {
        const now = new Date();
        const past = new Date(isoTime);
        const diff = Math.floor((now - past) / 1000);
        if (diff < 60) return `${diff} giây trước`;
        if (diff < 3600) return `${Math.floor(diff / 60)} phút trước`;
        if (diff < 86400) return `${Math.floor(diff / 3600)} giờ trước`;
        return `${Math.floor(diff / 86400)} ngày trước`;
    };

    const fetchNotifications = async () => {
        try {
            if (!user?.id) return;
            const data = await getNotificationsByUserId(user.id);
            const transformed = data.map(n => ({
                ...n,
                id: n._id || n.id // fallback
            }));
            setNotifications(transformed);
            setUnreadCount(transformed.filter(n => !n.isViewed).length);
        } catch (err) {
            console.error("Lỗi khi tải thông báo:", err);
        }
    };

    useEffect(() => {
        fetchNotifications();
    }, [user?.id]);

    const handleMarkAsViewed = async (id) => {
        try {
            if (!id) return;
            await markNotificationAsViewed(id);
            setNotifications(prev =>
                prev.map(n => n.id === id ? { ...n, isViewed: true } : n)
            );
            setUnreadCount(prev => Math.max(0, prev - 1));
        } catch (err) {
            console.error("Lỗi khi đánh dấu đã đọc:", err);
        }
    };

    return (
        <Dropdown align="end">
            <Dropdown.Toggle variant="link" className="position-relative p-0 border-0 text-white">
                <BellFill size={22} />
                {unreadCount > 0 && (
                    <Badge
                        bg="danger"
                        pill
                        className="position-absolute top-0 start-100 translate-middle"
                    >
                        {unreadCount}
                    </Badge>
                )}
            </Dropdown.Toggle>

            <Dropdown.Menu
                style={{ minWidth: '320px', maxHeight: '400px', overflowY: 'auto' }}
                className="bg-dark text-white shadow"
            >
                <Dropdown.Header className="text-white">Thông báo</Dropdown.Header>
                {notifications.length === 0 ? (
                    <Dropdown.ItemText className="text-secondary">
                        Không có thông báo nào
                    </Dropdown.ItemText>
                ) : (
                    notifications.map((n) => (
                        <Dropdown.Item
                            key={n.id}
                            onMouseEnter={() => !n.isViewed && handleMarkAsViewed(n.id)}
                            className={`custom-notify-item d-flex justify-content-between align-items-start py-2 px-3 rounded mb-1 ${
                                !n.isViewed ? 'bg-secondary bg-opacity-10' : ''
                            }`}
                            style={{ cursor: 'pointer', position: 'relative', color: 'white' }}
                        >
                            <div className="flex-grow-1 me-2">
                                <div className="fw-bold notify-title">{n.title}</div>
                                <div style={{ fontSize: '0.85rem', color: 'lightgray' }}>{n.content}</div>
                                <div style={{ fontSize: '0.75rem', color: '#aaa' }}>{formatTimeAgo(n.createAt)}</div>
                            </div>

                            {!n.isViewed && (
                                <div
                                    style={{
                                        width: '12px',
                                        height: '12px',
                                        backgroundColor: 'red',
                                        borderRadius: '50%',
                                        position: 'absolute',
                                        top: '16px',
                                        right: '12px',
                                    }}
                                />
                            )}
                        </Dropdown.Item>
                    ))
                )}
            </Dropdown.Menu>
        </Dropdown>
    );
};

export default NotificationBell;
