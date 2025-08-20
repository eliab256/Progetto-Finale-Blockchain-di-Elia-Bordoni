import React, { useState } from 'react';

interface NftCardProps {
    tokenId: number;
    onPlay?: (nft: NftData) => void;
}

export const NftCard: React.FC<NftCardProps> = ({ tokenId, onPlay }) => {
    const [videoLoading, setVideoLoading] = useState(true);
    const [videoError, setVideoError] = useState(false);

    const handleVideoLoad = () => {
        setVideoLoading(false);
    };

    const handleVideoError = () => {
        setVideoLoading(false);
        setVideoError(true);
    };

    const handlePlayClick = () => {
        onPlay?.(nft);
    };

    // Utility per ottenere colori basati sui valori
    const getDifficultyColor = (difficulty: number) => {
        if (difficulty <= 2) return 'bg-green-100 text-green-800';
        if (difficulty <= 4) return 'bg-yellow-100 text-yellow-800';
        return 'bg-red-100 text-red-800';
    };

    const getLevelColor = (level: string) => {
        switch (level.toLowerCase()) {
            case 'beginner':
                return 'bg-blue-100 text-blue-800';
            case 'intermediate':
                return 'bg-purple-100 text-purple-800';
            case 'advanced':
                return 'bg-orange-100 text-orange-800';
            default:
                return 'bg-gray-100 text-gray-800';
        }
    };

    const getStyleColor = (style: string) => {
        switch (style.toLowerCase()) {
            case 'hatha':
                return 'bg-indigo-100 text-indigo-800';
            case 'vinyasa':
                return 'bg-pink-100 text-pink-800';
            case 'ashtanga':
                return 'bg-red-100 text-red-800';
            case 'yin':
                return 'bg-teal-100 text-teal-800';
            default:
                return 'bg-gray-100 text-gray-800';
        }
    };

    // Estrai attributi principali
    const level = nft.metadata.attributes.find(attr => attr.trait_type === 'Level')?.value as string;
    const duration = nft.metadata.attributes.find(attr => attr.trait_type === 'Duration')?.value as string;
    const lessons = nft.metadata.attributes.find(attr => attr.trait_type === 'Lessons')?.value as number;
    const difficulty = nft.metadata.attributes.find(attr => attr.trait_type === 'Difficulty')?.value as number;
    const focus = nft.metadata.attributes.find(attr => attr.trait_type === 'Focus')?.value as string;
    const accessibility = nft.metadata.attributes.find(attr => attr.trait_type === 'Accessibility')?.value as string;

    return (
        <div className={`bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-2xl transition-all duration-300`}>
            {/* Video Preview */}
            <div className="aspect-video relative bg-gray-900 group">
                {videoLoading && (
                    <div className="absolute inset-0 flex items-center justify-center bg-gray-100 z-10">
                        <div className="text-center">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mb-2 mx-auto"></div>
                            <span className="text-sm text-gray-500">Loading video...</span>
                        </div>
                    </div>
                )}

                {videoError ? (
                    <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-gray-100 to-gray-200">
                        <div className="text-center">
                            <div className="text-4xl mb-2">🧘‍♀️</div>
                            <span className="text-gray-500 text-sm">Video not available</span>
                        </div>
                    </div>
                ) : (
                    <div className="relative h-full">
                        <video
                            src={nft.videoUrl}
                            className={`w-full h-full object-cover transition-opacity duration-300 ${
                                videoLoading ? 'opacity-0' : 'opacity-100'
                            }`}
                            onLoadedData={handleVideoLoad}
                            onError={handleVideoError}
                            muted
                            preload="metadata"
                            poster="" // Rimuovi poster di default
                        />

                        {/* Play Button Overlay */}
                        <div
                            className="absolute inset-0 flex items-center justify-center bg-black bg-opacity-40 opacity-0 group-hover:opacity-100 transition-opacity duration-300 cursor-pointer"
                            onClick={handlePlayClick}
                        >
                            <div className="bg-white bg-opacity-90 rounded-full p-4 shadow-lg hover:bg-opacity-100 transition-all duration-200 hover:scale-110">
                                <svg className="w-8 h-8 text-blue-600 ml-1" fill="currentColor" viewBox="0 0 20 20">
                                    <path
                                        fillRule="evenodd"
                                        d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"
                                        clipRule="evenodd"
                                    />
                                </svg>
                            </div>
                        </div>

                        {/* Token ID Badge */}
                        <div className="absolute top-3 right-3 bg-black bg-opacity-50 text-white text-xs px-2 py-1 rounded-full">
                            #{nft.tokenId}
                        </div>
                    </div>
                )}
            </div>

            {/* Content */}
            <div className="p-6">
                {/* Header */}
                <div className="mb-3">
                    <h3 className="font-bold text-xl text-gray-900 mb-1 line-clamp-1">{nft.metadata.name}</h3>
                    <p className="text-gray-600 text-sm line-clamp-2 leading-relaxed">{nft.metadata.description}</p>
                </div>

                {/* Main Stats */}
                <div className="grid grid-cols-2 gap-3 mb-4">
                    <div className="text-center p-3 bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg">
                        <div className="text-lg font-bold text-blue-900">{lessons}</div>
                        <div className="text-xs text-blue-700 font-medium">Lessons</div>
                    </div>
                    <div className="text-center p-3 bg-gradient-to-br from-green-50 to-green-100 rounded-lg">
                        <div className="text-lg font-bold text-green-900">{duration}</div>
                        <div className="text-xs text-green-700 font-medium">Duration</div>
                    </div>
                </div>

                {/* Focus */}
                {focus && (
                    <div className="mb-3">
                        <div className="text-xs text-gray-500 uppercase tracking-wide font-medium">Focus</div>
                        <div className="text-sm text-gray-700 font-medium">{focus}</div>
                    </div>
                )}

                {/* Tags */}
                <div className="flex flex-wrap gap-2">
                    {level && (
                        <span className={`text-xs px-3 py-1 rounded-full font-medium ${getLevelColor(level)}`}>
                            {level}
                        </span>
                    )}

                    {difficulty && (
                        <span
                            className={`text-xs px-3 py-1 rounded-full font-medium ${getDifficultyColor(difficulty)}`}
                        >
                            Level {difficulty}/5
                        </span>
                    )}

                    <span
                        className={`text-xs px-3 py-1 rounded-full font-medium ${getStyleColor(
                            nft.metadata.properties.style
                        )}`}
                    >
                        {nft.metadata.properties.style}
                    </span>

                    {accessibility === 'Full' && (
                        <span className="text-xs px-3 py-1 rounded-full font-medium bg-emerald-100 text-emerald-800">
                            ♿ Accessible
                        </span>
                    )}
                </div>
            </div>
        </div>
    );
};
