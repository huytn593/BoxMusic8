import React, { useState, useEffect } from 'react';
import { useSearchParams, Link, useNavigate } from 'react-router-dom';
import { PlayCircle } from 'lucide-react';
import { fetchSearchResults } from '../services/searchService';
import '../styles/Search.css';
import { useMusicPlayer } from '../context/musicPlayerContext';
import { Badge, Spinner, Container } from "react-bootstrap";

const MusicCard = ({ track, onPlay, onInfo }) => {
    return (
        <div className="search-music-card" onClick={() => onInfo(track)}>
            <div className="search-card-image-container">
                <img
                    src={track.imageUrl || '/images/default-music.jpg'}
                    alt={track.title}
                    className="search-card-image"
                />
                {!track.isPublic && (
                    <Badge bg="warning" text="dark" className="vip-badge">
                        👑 VIP
                    </Badge>
                )}
                <div className="search-card-overlay">
                    <button
                        className="play-button"
                        onClick={(e) => {
                            e.stopPropagation();
                            onPlay(track);
                        }}
                    >
                        <PlayCircle size={50} />
                    </button>
                </div>
            </div>
            <div className="search-card-info">
                <p className="search-card-title">{track.title}</p>
                <p className="search-card-artist">{track.artistName ? track.artistName : 'Musicresu'}</p>
            </div>
        </div>
    );
};

const UserCard = ({ user }) => (
    <Link to={`/personal-profile/${user.id}`} className="search-user-card">
        <img
            src={user.avatarBase64 || '/images/default-avatar.png'}
            alt={user.fullname}
            className="search-user-avatar"
        />
        <div className="search-user-info">
            <div className="search-user-fullname">{user.fullname}</div>
            <div className="search-user-username">@{user.username}</div>
        </div>
    </Link>
);


const SearchForm = () => {
    const [searchParams] = useSearchParams();
    const query = searchParams.get('query') || searchParams.get('q') || '';
    const [results, setResults] = useState({ tracks: [], users: [] });
    const [loading, setLoading] = useState(false);
    const { playTrackList } = useMusicPlayer();
    const navigate = useNavigate();

    useEffect(() => {
        if (!query) {
            setResults({ tracks: [], users: [] });
            return;
        }
        setLoading(true);
        fetchSearchResults(query)
            .then(data => {
                const mappedTracks = data.tracks.map(track => ({
                    ...track,
                    artist: track.artistName,
                    imageUrl: track.imageBase64 || '/images/default-music.jpg'
                }));
                setResults({ ...data, tracks: mappedTracks });
            })
            .catch(() => setResults({ tracks: [], users: [] }))
            .finally(() => setLoading(false));
    }, [query]);

    const handlePlayTrack = (track) => {
        const searchPlaylist = results.tracks.map(t => ({
            id: t.id,
            title: t.title,
            subtitle: t.artistName || 'Musicresu',
            isPublic: t.isPublic,
            imageUrl: t.imageBase64 || '/images/default-music.jpg',
            url: t.audioUrl || ''
        }));

        const trackIndex = searchPlaylist.findIndex(t => t.id === track.id);

        if (trackIndex !== -1) {
            playTrackList(searchPlaylist, trackIndex);
        }
    };

    return (
        <div className="search-page">
            {loading ? (
                <div className="loading-container">
                    <Spinner animation="border" role="status" />
                </div>
            ) : (
                <Container fluid className="search-container py-4">
                    <div className="search-header">
                        <h1 className="search-title">
                            Kết quả tìm kiếm cho <span className="search-query">"{query}"</span>
                        </h1>
                    </div>

                    {!query || (results.tracks.length === 0 && results.users.length === 0) ? (
                        <div className="search-empty-state text-center">
                            <img src="/images/default-music.jpg" alt="No results" className="empty-search-img mb-4" />
                            <h3>Không tìm thấy kết quả</h3>
                            <p>Vui lòng thử sử dụng từ khóa khác.</p>
                        </div>
                    ) : (
                        <>
                            {results.tracks.length > 0 && (
                                <section className="search-section">
                                    <h2 className="search-section-title">Bài hát</h2>
                                    <div className="search-grid">
                                        {results.tracks.map((track) => (
                                            <MusicCard
                                                key={track.id}
                                                track={track}
                                                onPlay={handlePlayTrack}
                                                onInfo={(track) => navigate(`/track/${track.id}`)}
                                            />
                                        ))}
                                    </div>
                                </section>
                            )}

                            {results.users.length > 0 && (
                                <section className="search-section">
                                    <h2 className="search-section-title">Người dùng</h2>
                                    <div className="user-grid">
                                        {results.users.map((user) => (
                                            <UserCard key={user.id} user={user} />
                                        ))}
                                    </div>
                                </section>
                            )}
                        </>
                    )}
                </Container>
            )}
        </div>
    );
};

export default SearchForm;