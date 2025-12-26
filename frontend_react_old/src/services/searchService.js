import axios from 'axios';

const API_BASE = process.env.REACT_APP_API_BASE_URL;

export const fetchSearchResults = async (query) => {
  const response = await axios.get(`${API_BASE}/api/search?query=${encodeURIComponent(query)}`);
  return response.data;
};
