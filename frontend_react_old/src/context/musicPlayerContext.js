import { createContext, useContext, useState, useEffect } from "react";
import { getTrackById } from "../services/trackService";
import { updateHistory } from "../services/playHistoryService";

const MusicPlayerContext = createContext();

export const MusicPlayerProvider = ({ children }) => {
    const [playlist, setPlaylist] = useState([]);
    const [currentTrackIndex, setCurrentTrackIndex] = useState(0);
    const [audioUrl, setAudioUrl] = useState('');
    const [isPlaying, setIsPlaying] = useState(false);

    const currentTrack = playlist[currentTrackIndex] || null;

    const playTrackList = (tracks, index = 0) => {
        setPlaylist(tracks);
        setCurrentTrackIndex(index);
        setIsPlaying(true);
    };


    useEffect(() => {
        const fetchAudioUrl = async () => {
            if (!currentTrack?.id) {
                setAudioUrl('');
                return;
            }

            try {
                const data = await getTrackById(currentTrack.id);
                setAudioUrl(data.audioUrl);

                // Lưu lịch sử nghe nhạc
                await updateHistory(currentTrack.id);

            } catch (error) {
                setCurrentTrackIndex(currentTrackIndex + 1 % playlist.length);
            }
        };

        fetchAudioUrl();
    }, [currentTrack]);

    return (
        <MusicPlayerContext.Provider value={{
            playlist,
            currentTrack,
            currentTrackIndex,
            audioUrl,
            isPlaying,
            setIsPlaying,
            playTrackList,
        }}>
            {children}
        </MusicPlayerContext.Provider>
    );
};

export const useMusicPlayer = () => useContext(MusicPlayerContext);
