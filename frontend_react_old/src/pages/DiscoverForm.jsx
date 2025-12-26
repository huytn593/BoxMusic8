import React, { useEffect, useState } from 'react';
import { Container, Button, Badge, Spinner } from 'react-bootstrap';
import { PlayCircle, Info, ChevronRight, ChevronLeft } from 'lucide-react';
import { getTopLikeTracks, getTopTracks } from "../services/trackService";
import { useMusicPlayer } from '../context/musicPlayerContext';
import '../styles/Discover.css';
import { useNavigate } from "react-router-dom";

const MusicCard = ({ track, onPlay, onInfo }) => {
    return (
        <div className="discover-music-card" onClick={() => onInfo(track)}>
            <div className="discover-card-image-container">
                <img
                    src={track.imageUrl || '/images/default-music.jpg'}
                    alt={track.title}
                    className="discover-card-image"
                />
                {!track.isPublic && (
                    <Badge bg="warning" text="dark" className="vip-badge">
                        👑 VIP
                    </Badge>
                )}
                <div className="discover-card-overlay">
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
            <div className="discover-card-info">
                <p className="discover-card-title">{track.title}</p>
                <p className="discover-card-artist">{track.artistName ? track.artistName : 'Musicresu'}</p>
            </div>
        </div>
    );
};

const ScrollableSection = ({ title, items, onPlay, onInfo }) => {
    const visibleCount = 5;
    const [startIndex, setStartIndex] = useState(0);
    const maxStartIndex = Math.max(0, items.length - visibleCount);

    const handlePrev = () => setStartIndex((prev) => Math.max(prev - visibleCount, 0));
    const handleNext = () => setStartIndex((prev) => Math.min(prev + visibleCount, maxStartIndex));

    useEffect(() => setStartIndex(0), [items]);

    const visibleItems = items.slice(startIndex, startIndex + visibleCount);

    if (!items || items.length === 0) {
        return <div className="text-center mt-4 text-white">Không có bài hát nào trong danh sách này.</div>;
    }

    return (
        <div className="discover-section mb-5">
            <h2 className="discover-section-title">{title}</h2>
            <div className="scrollable-wrapper position-relative">
                <div className="discover-grid">
                    {items.map((item) => (
                        <MusicCard
                            key={item.id}
                            track={item}
                            onPlay={onPlay}
                            onInfo={onInfo}
                        />
                    ))}
                </div>
                {/* Note: If you want carousel-like buttons, they would need different logic 
                    as the current layout shows all cards in a scrolling container or wraps them. 
                    For simplicity, this example removes them in favor of a clean grid. */}
            </div>
        </div>
    );
};

const DiscoverForm = () => {
    const [trendingSongs, setTrendingSongs] = useState([]);
    const [favoriteSongs, setFavoriteSongs] = useState([]);
    const [isLoading, setIsLoading] = useState(true);
    const navigate = useNavigate();
    const { playTrackList } = useMusicPlayer();

    useEffect(() => {
        const fetchData = async () => {
            setIsLoading(true);
            try {
                const [trackList, likeLists] = await Promise.all([
                    getTopTracks(),
                    getTopLikeTracks()
                ]);

                const mapTrackData = (track, index) => ({
                    id: track.id || index,
                    title: track.title || `Bài hát ${index + 1}`,
                    artistName: track.artistName ? track.artistName : 'Musicresu',
                    imageUrl: track.imageBase64 || '/images/default-music.jpg',
                    isPublic: track.isPublic,
                });

                setTrendingSongs(trackList.map(mapTrackData));
                setFavoriteSongs(likeLists.map(mapTrackData));
            } catch (error) {
                console.error("Failed to fetch discover data:", error);
            } finally {
                setIsLoading(false);
            }
        };
        fetchData();
    }, []);

    const createPlayHandler = (playlist) => (track) => {
        const index = playlist.findIndex(t => t.id === track.id);
        if (index !== -1) {
            playTrackList(playlist, index);
        }
    };

    if (isLoading) {
        return (
            <div className="loading-container">
                <Spinner animation="border" />
            </div>
        );
    }

    return (
        <div className="discover-page">
            <Container fluid className="discover-container py-4">
                <ScrollableSection
                    title="Phổ biến nhất"
                    items={trendingSongs}
                    onPlay={createPlayHandler(trendingSongs)}
                    onInfo={(track) => navigate(`/track/${track.id}`)}
                />
                <ScrollableSection
                    title="Được yêu thích nhất"
                    items={favoriteSongs}
                    onPlay={createPlayHandler(favoriteSongs)}
                    onInfo={(track) => navigate(`/track/${track.id}`)}
                />
            </Container>
        </div>
    );
};

export default DiscoverForm;
