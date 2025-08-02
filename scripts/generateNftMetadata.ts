import * as fs from 'fs';
import * as path from 'path';

interface YogaCourse {
    id: number;
    name: string;
    style: string;
    level: string;
    lessons: number;
    duration: string;
    accessibility: string;
    focus: string;
    difficulty: number;
    description: string;
}

interface Attribute {
    trait_type: string;
    value: string | number;
}

interface Metadata {
    name: string;
    description: string;
    image: string;
    external_url: string;
    attributes: Attribute[];
    properties: {
        category: string;
        course_type: string;
        accessibility_level: string;
        redeemable: boolean;
        instructor_certified: boolean;
        style: string;
    };
}

const yoyoCourses: YogaCourse[] = [
    {
        id: 1,
        name: 'Hatha Base',
        style: 'Hatha',
        level: 'Beginner',
        lessons: 8,
        duration: '45 minutes',
        accessibility: 'Full',
        focus: 'Postures and Breathing',
        difficulty: 2,
        description:
            'Introductory course to the fundamental postures of Hatha Yoga with adaptations for various physical needs.',
    },
    {
        id: 2,
        name: 'Vinyasa Flow Beginners',
        style: 'Vinyasa',
        level: 'Beginner',
        lessons: 10,
        duration: '50 minutes',
        accessibility: 'Full',
        focus: 'Fluid Sequences',
        difficulty: 3,
        description:
            'Introduction to Vinyasa Flow with gentle sequences and modifications for different mobility levels.',
    },
    {
        id: 3,
        name: 'Seated Gentle Yoga',
        style: 'Gentle',
        level: 'Adapted',
        lessons: 6,
        duration: '30 minutes',
        accessibility: 'Wheelchair',
        focus: 'Upper Mobility',
        difficulty: 1,
        description: 'Yoga sequences specifically designed for wheelchair users, focusing on chest and arms.',
    },
    {
        id: 4,
        name: 'Prenatal Yoga First Trimester',
        style: 'Prenatal',
        level: 'Specialized',
        lessons: 12,
        duration: '40 minutes',
        accessibility: 'Pregnancy',
        focus: 'Maternal Wellness',
        difficulty: 2,
        description:
            'Safe yoga practice for the first trimester of pregnancy with modified postures and relaxation techniques.',
    },
    {
        id: 5,
        name: 'Modified Primary Ashtanga',
        style: 'Ashtanga',
        level: 'Intermediate',
        lessons: 15,
        duration: '60 minutes',
        accessibility: 'Partial',
        focus: 'Traditional Series',
        difficulty: 4,
        description:
            'Primary Ashtanga series with modifications for physical limitations, preserving the essence of the practice.',
    },
    {
        id: 6,
        name: 'Meditative Yin Yoga',
        style: 'Yin',
        level: 'All Levels',
        lessons: 8,
        duration: '75 minutes',
        accessibility: 'Full',
        focus: 'Deep Relaxation',
        difficulty: 1,
        description:
            'Passive postures held for extended periods for deep relaxation, adaptable to all physical conditions.',
    },
    {
        id: 7,
        name: 'Yoga with Prosthetics',
        style: 'Adaptive',
        level: 'Specialized',
        lessons: 10,
        duration: '45 minutes',
        accessibility: 'Prosthetics',
        focus: 'Postural Adaptation',
        difficulty: 3,
        description: 'Specific sequences for prosthesis users, focusing on balance and posture adaptation.',
    },
    {
        id: 8,
        name: 'Inclusive Power Yoga',
        style: 'Power',
        level: 'Advanced',
        lessons: 12,
        duration: '55 minutes',
        accessibility: 'Partial',
        focus: 'Strength and Endurance',
        difficulty: 5,
        description: 'Dynamic and intense yoga with variations for different physical ability levels.',
    },
    {
        id: 9,
        name: 'Therapeutic Laughter Yoga',
        style: 'Laughter',
        level: 'All Levels',
        lessons: 6,
        duration: '35 minutes',
        accessibility: 'Full',
        focus: 'Emotional Well-being',
        difficulty: 1,
        description: 'Combination of laughter and yoga to improve mood and reduce stress, accessible to all.',
    },
    {
        id: 10,
        name: 'Modified Bikram Hot Yoga',
        style: 'Bikram',
        level: 'Intermediate',
        lessons: 14,
        duration: '90 minutes',
        accessibility: 'Partial',
        focus: 'Fixed Series',
        difficulty: 4,
        description:
            '26 Bikram postures with physical limitation adaptations, practiced in a virtual heated environment.',
    },
    {
        id: 11,
        name: 'Therapeutic Restorative Yoga',
        style: 'Restorative',
        level: 'Therapeutic',
        lessons: 8,
        duration: '60 minutes',
        accessibility: 'Full',
        focus: 'Recovery and Healing',
        difficulty: 1,
        description: 'Restorative yoga for injury recovery or those seeking a very gentle approach.',
    },
    {
        id: 12,
        name: 'Vinyasa Intermediate Plus',
        style: 'Vinyasa',
        level: 'Intermediate',
        lessons: 12,
        duration: '60 minutes',
        accessibility: 'Partial',
        focus: 'Advanced Transitions',
        difficulty: 4,
        description: 'Intermediate Vinyasa Flow with complex transitions and variations for various abilities.',
    },
    {
        id: 13,
        name: 'Guided Yoga Nidra',
        style: 'Nidra',
        level: 'All Levels',
        lessons: 5,
        duration: '45 minutes',
        accessibility: 'Full',
        focus: 'Conscious Relaxation',
        difficulty: 1,
        description: 'Deep guided relaxation practice, suitable for anyone in any position.',
    },
    {
        id: 14,
        name: 'Kundalini Vital Energy',
        style: 'Kundalini',
        level: 'Intermediate',
        lessons: 10,
        duration: '50 minutes',
        accessibility: 'Partial',
        focus: 'Energy and Mantras',
        difficulty: 3,
        description: 'Awakening of Kundalini energy through movement, breathing and mantras, with modifications.',
    },
    {
        id: 15,
        name: 'Yoga for Active Seniors',
        style: 'Senior',
        level: 'Specialized',
        lessons: 8,
        duration: '40 minutes',
        accessibility: 'Senior',
        focus: 'Mobility and Balance',
        difficulty: 2,
        description: 'Yoga for over-65s focusing on balance, joint mobility and fall prevention.',
    },
    {
        id: 16,
        name: 'Iyengar Precision',
        style: 'Iyengar',
        level: 'Intermediate',
        lessons: 12,
        duration: '75 minutes',
        accessibility: 'Props Required',
        focus: 'Perfect Alignment',
        difficulty: 4,
        description: 'Iyengar yoga focused on precise alignment, using props to support every body.',
    },
    {
        id: 17,
        name: 'Postpartum Recovery Yoga',
        style: 'Postnatal',
        level: 'Specialized',
        lessons: 10,
        duration: '45 minutes',
        accessibility: 'Post-Pregnancy',
        focus: 'Muscle Recovery',
        difficulty: 2,
        description: 'Sequences for postpartum recovery, core strengthening and stress relief.',
    },
    {
        id: 18,
        name: 'Dynamic Rocket Yoga',
        style: 'Rocket',
        level: 'Advanced',
        lessons: 14,
        duration: '75 minutes',
        accessibility: 'Limited',
        focus: 'Intense Sequences',
        difficulty: 5,
        description: 'Dynamic and acrobatic yoga with adaptations for those seeking intensity despite limitations.',
    },
    {
        id: 19,
        name: 'Integrated Sensory Yoga',
        style: 'Sensory',
        level: 'Specialized',
        lessons: 8,
        duration: '50 minutes',
        accessibility: 'Blind/Visually Impaired',
        focus: 'Proprioception',
        difficulty: 3,
        description:
            'Yoga for blind and visually impaired practitioners, focusing on proprioception and spatial awareness.',
    },
    {
        id: 20,
        name: 'Adaptive Aerial Yoga',
        style: 'Aerial',
        level: 'Intermediate',
        lessons: 10,
        duration: '60 minutes',
        accessibility: 'Aerial Support',
        focus: 'Assisted Suspension',
        difficulty: 4,
        description: 'Modified aerial yoga using the hammock as therapeutic support for all abilities.',
    },
];

function generateNFTMetadata(course: YogaCourse): Metadata {
    return {
        name: `YoYo Course ${course.name} #${String(course.id).padStart(3, '0')}`,
        description: `NFT granting access to the ${course.name} inclusive yoga course by YoYo. Includes ${course.lessons} customizable lessons for various mobility needs. ${course.description}`,
        image: `https://ipfs.io/ipfs/QmYourImageHash${String(course.id).padStart(3, '0')}`,
        external_url: `https://yoyo-app.com/nft/course/${String(course.id).padStart(3, '0')}`,
        attributes: [
            { trait_type: 'Yoga Style', value: course.style },
            { trait_type: 'Level', value: course.level },
            { trait_type: 'Number of Lessons', value: course.lessons },
            { trait_type: 'Lesson Duration', value: course.duration },
            { trait_type: 'Accessibility', value: course.accessibility },
            { trait_type: 'Main Focus', value: course.focus },
            { trait_type: 'Difficulty', value: course.difficulty },
            { trait_type: 'Category', value: 'Course' },
        ],
        properties: {
            category: 'course',
            course_type: course.name.toLowerCase().replace(/\s+/g, '_'),
            accessibility_level: course.accessibility.toLowerCase().replace(/\s+/g, '_'),
            redeemable: true,
            instructor_certified: true,
            style: course.style.toLowerCase(),
        },
    };
}

function generateAllCourseNFTs(): void {
    const metadataDir = path.join(__dirname, 'metadata');

    if (!fs.existsSync(metadataDir)) {
        fs.mkdirSync(metadataDir, { recursive: true });
    }

    console.log('Generating YoYo course NFT metadata...\n');

    yoyoCourses.forEach(course => {
        const metadata = generateNFTMetadata(course);
        const fileName = `${String(course.id).padStart(3, '0')}.json`;
        const filePath = path.join(metadataDir, fileName);

        fs.writeFileSync(filePath, JSON.stringify(metadata, null, 2));

        console.log(`${course.id}/20 - Created: ${metadata.name}`);
        console.log(
            `Lessons: ${course.lessons} | Duration: ${course.duration} | Accessibility: ${course.accessibility}`
        );
        console.log(`File: ${fileName}\n`);
    });

    console.log('Metadata generation complete.');
    console.log(`${yoyoCourses.length} JSON files created in the 'metadata' folder`);

    const styleStats: Record<string, number> = {};
    const levelStats: Record<string, number> = {};

    yoyoCourses.forEach(course => {
        styleStats[course.style] = (styleStats[course.style] || 0) + 1;
        levelStats[course.level] = (levelStats[course.level] || 0) + 1;
    });

    console.log('\nCourses per yoga style:');
    Object.entries(styleStats).forEach(([style, count]) => {
        console.log(`${style}: ${count} courses`);
    });

    console.log('\nCourses per level:');
    Object.entries(levelStats).forEach(([level, count]) => {
        console.log(`${level}: ${count} courses`);
    });
}

// Run
generateAllCourseNFTs();
