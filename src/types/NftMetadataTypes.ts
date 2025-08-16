export interface Attribute {
    trait_type: string;
    value: string | number;
}

export interface Properties {
    category: string;
    course_type: string;
    accessibility_level: string;
    redeemable: boolean;
    instructor_certified: boolean;
    style: string;
}

export interface YogaCourseMetadata {
    name: string;
    description: string;
    image: string;
    attributes: Attribute[];
    properties: Properties;
}
